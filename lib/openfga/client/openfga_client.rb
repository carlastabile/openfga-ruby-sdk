# frozen_string_literal: true

require 'cgi'
require 'concurrent'
require 'set'

module OpenFga
  class SdkClient
    PAGE_SIZE = 50
    CREDENTIALS_METHODS = %i[none api_token client_credentials].freeze

    def initialize(config = {})
      raise ConfigurationNilError.new(:api_url) unless config[:api_url]

      @config = config

      @config[:credentials] ||= {
        method: :none
      }

      @logger = new_logger(@config)
      @logger.debug('Using custom logger instance') if @config[:logger]

      telemetry_config = resolve_telemetry_config(@config[:telemetry])
      @telemetry_metrics = Telemetry.get(telemetry_config)

      # Later we can support custom token managers.
      @token_manager = case @config[:credentials][:method]
                       when :none
                         TokenManager::NoopTokenManager.new
                       when :api_token
                         TokenManager::StaticTokenManager.new(@config.dig(:credentials, :api_token))
                       when :client_credentials
                         oauth_config = TokenManager::Oauth2TokenManager::Config.new(
                           client_id: @config.dig(:credentials, :client_id),
                           client_secret: @config.dig(:credentials, :client_secret),
                           token_issuer: @config.dig(:credentials, :api_token_issuer),
                           audience: @config.dig(:credentials, :api_audience),
                           logger: @logger
                         )

                         TokenManager::Oauth2TokenManager.new(oauth_config, metrics: @telemetry_metrics)
                       else
                         valid_methods = CREDENTIALS_METHODS.join(', ')

                         raise ConfigurationError, "Unknown credentials method: #{@config[:credentials]}" \
                           "Supported methods: #{valid_methods}"
      end

      api_client_config = Configuration.new do |c|
        c.server_index = nil
        c.host = @config[:api_url]
        c.scheme = URI(@config[:api_url]).scheme
        c.logger = @logger
        c.debugging = true if @config[:logger]
      end

      inner_api_client = ApiClient.new(api_client_config)
      effective_telemetry_config = telemetry_config || Telemetry.configuration
      if effective_telemetry_config.http_request_duration.enabled?
        inner_api_client.instance_variable_set(:@telemetry_metrics, @telemetry_metrics)
        inner_api_client.singleton_class.prepend(Telemetry::HttpDurationTracker)
      end

      @api_client = OpenFga::OpenFgaApi.new(inner_api_client)
    end

    # Performs multiple relationship checks in a single batch request.
    #
    # @param body [Hash] The request body containing:
    #   - :checks [Array<Hash>] Each check item must include:
    #       - :tuple_key [Hash] The tuple key for the relationship to check, with:
    #           - :user [String] The user involved in the relationship.
    #           - :relation [String, Symbol] The relation to check (e.g. "reader" or :owner).
    #           - :object [String] The object involved in the relationship.
    #       - :correlation_id [String] Unique identifier for correlating the request with the response (max 36 chars, alphanumeric + hyphens).
    #       - :contextual_tuples [Hash] (optional) Additional contextual tuples to include in the check.
    #       - :context [Hash] (optional) Additional context for the check.
    #   - :opts [Hash] Optional parameters for the batch check:
    #       - :authorization_model_id [String] The ID of the authorization model.
    #       - :consistency [String] The consistency level for the checks.
    #       - :max_parallel_requests [Integer] Maximum concurrent requests \(default: 10\).
    #       - :max_batch_size [Integer] Maximum checks per batch \(default: 50\).
    #
    # @raise [ArgumentError] If the checks array is empty, or if any check item is missing required parameters.
    # @return [BatchCheckResponse] The result of the batch check operation with results keyed by correlation_id.
    def batch_check(body = {})
      checks = body[:checks]
      fail ArgumentError, "Missing the required parameter 'checks'" if checks.nil? || checks.empty?

      opts = body[:opts] || {}
      # Configuration with defaults matching Python SDK
      max_parallel_requests = opts[:max_parallel_requests] || 10
      max_batch_size = opts[:max_batch_size] || 50

      # Validate all checks first and check for duplicates
      correlation_ids = Set.new

      checks.each_with_index do |check, index|
        fail ArgumentError, "Missing 'tuple_key' in check item at index #{index}" if check[:tuple_key].nil?
        fail ArgumentError, "Missing 'correlation_id' in check item at index #{index}" if check[:correlation_id].nil?

        # Validate correlation_id format
        correlation_id = check[:correlation_id].to_s
        unless correlation_id.match?(/^[\w\d-]{1,36}$/)
          fail ArgumentError, "correlation_id must be alphanumeric with hyphens only, max 36 characters: #{correlation_id}"
        end

        # Check for duplicates
        if correlation_ids.include?(correlation_id)
          fail ArgumentError, "Duplicate correlation_id found: #{correlation_id}"
        end
        correlation_ids.add(correlation_id)
      end

      sid = store_id(opts)

      with_request_metrics(
        method_name: 'BatchCheck',
        extra_attrs: {
          Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID         => sid,
          Telemetry::Attributes::FGA_CLIENT_REQUEST_MODEL_ID         => authorization_model_id(opts),
          Telemetry::Attributes::FGA_CLIENT_REQUEST_BATCH_CHECK_SIZE => checks.length.to_s
        }
      ) do
        if checks.length <= max_batch_size
          execute_single_batch_check_with_info(checks, opts)
        else
          check_batches = checks.each_slice(max_batch_size).to_a
          all_results = process_batches_concurrently(check_batches, max_parallel_requests, opts)

          merged_results = {}
          all_results.each do |batch_response|
            merged_results.merge!(batch_response.result) if batch_response&.result
          end

          [BatchCheckResponse.new(result: merged_results), nil, nil]
        end
      end
    end

    # Checks whether a specific relationship exists in the store.
    # @param body [Hash] The request body containing check details
    #   - :user [String] The user involved in the relationship
    #   - :relation [String, Symbol] The relation to check (e.g. "reader", "owner")
    #   - :object [String] The object involved in the relationship
    #   - :contextual_tuples [Hash] Additional contextual tuples to include in the check:
    #      - :tuple_keys [Array<Hash>] Array of tuple key hashes
    #   - :opts [Hash] Optional parameters for the check request:
    #       - :authorization_model_id [String] The ID of the authorization model to use for the check
    #       - :context [Hash] Additional context for the check
    #       - :store_id [String] The ID of the store (required if not set in client config)
    # @raise [ArgumentError] If any of the required parameters (user, relation, or object) are missing
    # @return [CheckResponse] The result of the check operation
    def check(body = {})
      opts = body[:opts] || {}
      tuple_key = CheckRequestTupleKey.new({
                                             user: body[:user], relation: body[:relation].to_s, object: body[:object] })

      request_body = CheckRequest.new({ tuple_key: })

      unless body[:contextual_tuples].nil?
        tuple_keys = body[:contextual_tuples][:tuple_keys].map { |tuple_key| TupleKey.new(tuple_key) }
        request_body.contextual_tuples = ContextualTupleKeys.new(tuple_keys:)
      end

      request_body.context = opts[:context] unless opts[:context].nil?
      request_body.authorization_model_id = authorization_model_id(opts)

      sid = store_id(opts)
      with_request_metrics(
        method_name: 'Check',
        extra_attrs: {
          Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid,
          Telemetry::Attributes::FGA_CLIENT_REQUEST_MODEL_ID => request_body.authorization_model_id,
          Telemetry::Attributes::FGA_CLIENT_USER             => body[:user]
        }
      ) do
        @api_client.check_with_http_info(sid, request_body, wrap_options(opts))
      end
    end

    ## Creates a new OpenFGA store for storing authorization models and relationship tuples.
    # @param body [Hash] The request body with store details.
    #   - :name [String] The name of the store to create.
    #   - :opts [Hash] Optional parameters for the request.
    # @return [CreateStoreResponse] The response with the created store details.
    def create_store(body = {})
      request_body = OpenFga::CreateStoreRequest.new(body)
      opts = body[:opts] || {}

      with_request_metrics(method_name: 'CreateStore') do
        @api_client.create_store_with_http_info(request_body, wrap_options(opts))
      end
    end

    # Delete a store
    # Delete an OpenFGA store.
    # @param opts [Hash] Optional parameters for the request
    # @option opts [String] :store_id The ID of the store to delete (required if not set in client config)
    # @return [nil]
    def delete_store(opts = {})
      sid = store_id(opts)
      with_request_metrics(
        method_name: 'DeleteStore',
        extra_attrs: { Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid }
      ) do
        @api_client.delete_store_with_http_info(sid, wrap_options(opts))
      end
    end

    # Expands a relationship tuple to retrieve all users and groups that have the specified relation with the given object.
    # @param body [Hash] Expansion request details:
    #   - :relation [String, Symbol] The relation to expand (e.g. "reader", :writer)
    #   - :object [String] The object involved in the relationship
    #   - :contextual_tuples [Hash] Additional contextual tuples for the expansion
    #   - :opts [Hash] Optional parameters:
    #       - :store_id [String] Store ID (required if not set in client config)
    #       - :authorization_model_id [String] Authorization model ID for the expansion
    #       - :consistency [String] Consistency level ("UNSPECIFIED", "MINIMIZE_LATENCY", "HIGHER_CONSISTENCY")
    # @raise [ArgumentError] If :relation or :object is missing
    # @return [ExpandResponse] Expanded relationship tuples
    def expand(body = {})
      relation, object = body[:relation], body[:object]

      fail ArgumentError, "Missing the required parameter 'relation'" if relation.nil?
      fail ArgumentError, "Missing the required parameter 'object'" if object.nil?

      opts = body[:opts] || {}

      request_body = ExpandRequest.new(
        tuple_key: ExpandRequestTupleKey.new(relation:, object:),
        authorization_model_id: authorization_model_id(opts),
        consistency: opts[:consistency] || 'UNSPECIFIED'
      )

      if body.include?(:contextual_tuples)
        contextual_tuples = body[:contextual_tuples]
        tuple_keys = contextual_tuples[:tuple_keys].map { |tuple_key| TupleKey.new(tuple_key) }
        request_body.contextual_tuples = ContextualTupleKeys.new(tuple_keys:)
      end

      sid = store_id(opts)
      with_request_metrics(
        method_name: 'Expand',
        extra_attrs: {
          Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid,
          Telemetry::Attributes::FGA_CLIENT_REQUEST_MODEL_ID => request_body.authorization_model_id
        }
      ) do
        @api_client.expand_with_http_info(sid, request_body, wrap_options(opts))
      end
    end

    # Get a store
    # Returns an OpenFGA store by its identifier
    # @param opts [Hash] Optional parameters for the request
    # @option opts [String] :store_id The ID of the store to retrieve (required if not set in client config)
    # @return [GetStoreResponse] The response containing the store details
    def get_store(opts = {})
      sid = store_id(opts)
      with_request_metrics(
        method_name: 'GetStore',
        extra_attrs: { Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid }
      ) do
        @api_client.get_store_with_http_info(sid, wrap_options(opts))
      end
    end

    # List objects for a given user and relation.
    # Returns objects of a specified type for a user and relation.
    # @param body [Hash] Request body:
    #   - :user [String] User to list objects for.
    #   - :relation [String, Symbol] Relation to list objects for (e.g., "reader", :writer).
    #   - :type [String] Type of objects to list.
    #   - :contextual_tuples [Hash] (optional) Additional contextual tuples.
    #   - :context [Hash] (optional) Additional context.
    #   - :opts [Hash] (optional) Request options:
    #       - :store_id [String] Store ID (required if not set in client config).
    #       - :authorization_model_id [String] Authorization model ID.
    #       - :consistency [String] Consistency level ("UNSPECIFIED", "MINIMIZE_LATENCY", "HIGHER_CONSISTENCY").
    # @raise [ArgumentError] If :user, :relation, or :type is missing.
    # @return [ListObjectsResponse] List of objects for the user and relation.
    def list_objects(body = {})
      user = body[:user]
      relation = body[:relation]
      type = body[:type]
      contextual_tuples = body[:contextual_tuples]
      context = body[:context]
      opts = body[:opts] || {}

      fail ArgumentError, "Missing the required parameter 'user'" if user.nil?
      fail ArgumentError, "Missing the required parameter 'relation'" if relation.nil?
      fail ArgumentError, "Missing the required parameter 'type'" if type.nil?

      request_body = ListObjectsRequest.new(
        type:,
        relation:,
        user:,
        authorization_model_id: authorization_model_id(opts),
        consistency: opts[:consistency] || 'UNSPECIFIED'
      )

      unless contextual_tuples.nil?
        tuple_keys = contextual_tuples[:tuple_keys].map { |tuple_key| TupleKey.new(tuple_key) }
        request_body.contextual_tuples = ContextualTupleKeys.new(tuple_keys:)
      end

      request_body.context = context unless context.nil?

      sid = store_id(opts)
      with_request_metrics(
        method_name: 'ListObjects',
        extra_attrs: {
          Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid,
          Telemetry::Attributes::FGA_CLIENT_REQUEST_MODEL_ID => request_body.authorization_model_id,
          Telemetry::Attributes::FGA_CLIENT_USER             => user
        }
      ) do
        @api_client.list_objects_with_http_info(sid, request_body, wrap_options(opts))
      end
    end

    # List all stores
    # Returns a paginated list of OpenFGA stores and a continuation token to get additional stores. The continuation token will be empty if there are no more stores.
    # @param opts [Hash] Optional parameters for the request
    # @option opts [Integer] :page_size The number of stores to return per page
    # @option opts [String] :continuation_token The continuation token for pagination
    # @return [ListStoresResponse] The response containing the paginated list of stores
    def list_stores(opts = {})
      with_request_metrics(method_name: 'ListStores') do
        @api_client.list_stores_with_http_info(wrap_options(opts))
      end
    end

    # List users that have a specific relation with an object
    # Returns a list of all users that have the specified relation with the given object.
    # @param body [Hash] The request body containing list details
    # @option body [String, Symbol] :relation The relation to check for (e.g., "reader", "writer")
    # @option body [String] :object The object to check relations against
    # @option body [Array<Hash>] :user_filters Filter criteria for the users to return
    # @option body [Array<Hash>] :contextual_tuples Additional contextual tuples to include in the query
    # @option body [Hash] :context Additional context for the query
    # @option body [Hash] :opts Optional parameters for the request, including:
    #   - :authorization_model_id [String] The ID of the authorization model to use for the query
    #   - :consistency [String] The consistency level for the query (defaults to 'UNSPECIFIED')
    #   - :store_id [String] The store ID to query users from (required if not set in client config)
    # @raise [ArgumentError] If the required parameter 'relation' is missing
    # @raise [ArgumentError] If the required parameter 'object' is missing
    # @return [ListUsersResponse] The response containing the list of users
    def list_users(body = {})
      relation = body[:relation]
      object = body[:object]
      user_filters = body[:user_filters]
      contextual_tuples = body[:contextual_tuples]
      context = body[:context]
      opts = body[:opts] || {}

      fail ArgumentError, "Missing the required parameter 'relation'" if relation.nil?
      fail ArgumentError, "Missing the required parameter 'object'" if object.nil?

      request_body = ListUsersRequest.new(
        relation: relation.to_s,
        object:,
        context:,
        user_filters: (user_filters || []).map { |filter| UserTypeFilter.new(filter) },
        authorization_model_id: authorization_model_id(opts),
      )

      # Build the request body
      if contextual_tuples
        tuples = contextual_tuples.map { |tuple| TupleKey.new(tuple) }
        request_body.contextual_tuples = tuples
      end

      sid = store_id(opts)
      with_request_metrics(
        method_name: 'ListUsers',
        extra_attrs: {
          Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid,
          Telemetry::Attributes::FGA_CLIENT_REQUEST_MODEL_ID => request_body.authorization_model_id
        }
      ) do
        @api_client.list_users_with_http_info(sid, request_body, wrap_options(opts))
      end
    end

    # Read tuples from the store
    # Reads tuples from the store.
    # @param body [Hash] The request body containing read query details
    # @option body [String] :user The user to read tuples for
    # @option body [String, Symbol] :relation The relation to read tuples for
    # @option body [String] :object The object to read tuples for
    # @option opts [Integer] :page_size The number of tuples to return per page
    # @option opts [String] :continuation_token The continuation token for pagination
    # @option opts [String] :consistency The consistency level for the read operation
    # @option opts [String] :store_id The store ID to read tuples from (required if not set in client config)
    # @return [ReadResponse] The response containing the tuples
    def read(body = {})
      user = body[:user]
      relation = body[:relation]
      object = body[:object]
      opts = body[:opts] || {}

      request_body = ReadRequest.new(
        continuation_token: opts[:continuation_token],
        page_size: opts[:page_size] || PAGE_SIZE,
        consistency: opts[:consistency])

      if user || relation || object
        tuple_key = {}
        tuple_key[:user] = user if user
        tuple_key[:relation] = relation.to_s if relation
        tuple_key[:object] = object if object
        request_body.tuple_key = ReadRequestTupleKey.new(tuple_key)
      end

      sid = store_id(opts)
      with_request_metrics(
        method_name: 'Read',
        extra_attrs: { Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid }
      ) do
        @api_client.read_with_http_info(sid, request_body, wrap_options(opts))
      end
    end

    # Read assertions
    # Retrieve assertions for a specific store and authorization model
    # @param opts [Hash] Optional parameters for the request
    # @option opts [String] :store_id The ID of the store (required if not set in client config)
    # @option opts [String] :authorization_model_id The ID of the authorization model (required if not set in client config)
    # @raise [MissingStoreIdError] If the store_id is not provided
    # @raise [MissingAuthorizationModelIdError] If the authorization_model_id is not provided
    # @return [ReadAssertionsResponse] The response containing the assertions
    def read_assertions(opts = {})
      fail MissingAuthorizationModelIdError unless authorization_model_id(opts)

      sid = store_id(opts)
      model_id = authorization_model_id(opts)
      with_request_metrics(
        method_name: 'ReadAssertions',
        extra_attrs: {
          Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid,
          Telemetry::Attributes::FGA_CLIENT_REQUEST_MODEL_ID => model_id
        }
      ) do
        @api_client.read_assertions_with_http_info(sid, model_id, wrap_options(opts))
      end
    end

    # Read an authorization model
    # Retrieves a specific authorization model by its ID from a given store.
    # @param opts [Hash] Optional parameters for the request
    # @option opts [String] :store_id The ID of the store (required if not set in client config)
    # @option opts [String] :authorization_model_id The ID of the authorization model to read (required if not set in client config)
    # @raise [MissingStoreIdError] If the store_id is not provided
    # @raise [MissingAuthorizationModelIdError] If the authorization_model_id is not provided
    # @return [ReadAuthorizationModelResponse] The response containing the authorization model details
    def read_authorization_model(opts = {})
      fail MissingAuthorizationModelIdError unless authorization_model_id(opts)

      sid = store_id(opts)
      model_id = authorization_model_id(opts)
      with_request_metrics(
        method_name: 'ReadAuthorizationModel',
        extra_attrs: {
          Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid,
          Telemetry::Attributes::FGA_CLIENT_REQUEST_MODEL_ID => model_id
        }
      ) do
        @api_client.read_authorization_model_with_http_info(sid, model_id, wrap_options(opts))
      end
    end

    # Read all authorization models
    # Retrieves all authorization models for a specific store.
    # @param opts [Hash] Optional parameters for the request
    # @option opts [String] :store_id The ID of the store (required if not set in client config)
    # @raise [MissingStoreIdError] If the store_id is not provided
    # @return [ReadAuthorizationModelsResponse] The response containing the list of authorization models
    def read_authorization_models(opts = {})
      sid = store_id(opts)
      with_request_metrics(
        method_name: 'ReadAuthorizationModels',
        extra_attrs: { Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid }
      ) do
        @api_client.read_authorization_models_with_http_info(sid, wrap_options(opts))
      end
    end

    # Read changes
    # Reads the list of historical relationship tuple writes and deletes.
    # @param body [Hash] The request body containing change query details
    # @option body [String] :type Get the list of tuple changes that affect only this type
    # @option body [String] :start_time The start time of the range to read changes from. This is a timestamp in ISO 8601 format    # @param opts [Hash] Optional parameters for the request
    # @option opts [Integer] :page_size The number of pages to return in the request
    # @option opts [String] :continuation_token The continuation token to use to get the next page of results. This will be empty if there are no more results
    # @option opts [String] :store_id The store ID to read changes from (required if not set in client config)
    # @return [ReadChangesResponse] The response containing the list of changes
    def read_changes(opts = {})
      sid = store_id(opts)
      with_request_metrics(
        method_name: 'ReadChanges',
        extra_attrs: { Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid }
      ) do
        @api_client.read_changes_with_http_info(sid, wrap_options(opts))
      end
    end

    # Write tuples to the store.
    # Atomically creates, updates, or deletes relationship tuples for a given store.
    # @param body [Hash] The request body containing write details:
    #   - :writes [Array<Hash>] Tuples to add or update in the store.
    #   - :deletes [Array<Hash>] Tuples to remove from the store.
    #   - :opts [Hash] Optional parameters for the request:
    #       - :store_id [String] Store ID to write to (required if not set in client config).
    #       - :authorization_model_id [String] Authorization model ID to use for writing.
    # @return [WriteResponse] The response from the write operation.
    def write(body = {})
      opts = body[:opts] || {}
      request_body = WriteRequest.new(writes: body[:writes], deletes: body[:deletes])

      request_body.authorization_model_id = opts[:authorization_model_id] if opts[:authorization_model_id]

      sid = store_id(opts)
      with_request_metrics(
        method_name: 'Write',
        extra_attrs: {
          Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid,
          Telemetry::Attributes::FGA_CLIENT_REQUEST_MODEL_ID => request_body.authorization_model_id
        }
      ) do
        @api_client.write_with_http_info(sid, request_body, wrap_options(opts))
      end
    end

    # Writes assertions for a specific store and authorization model.
    # Updates or creates assertions used for testing authorization logic.
    # @param body [Hash] The request body containing assertions:
    #   - :assertions [Array<Hash>] The assertions to write.
    #   - :opts [Hash] Optional parameters:
    #       - :store_id [String] Store ID (required if not set in client config).
    #       - :authorization_model_id [String] Authorization model ID (required if not set in client config).
    # @raise [MissingStoreIdError] If store_id is missing.
    # @raise [MissingAuthorizationModelIdError] If authorization_model_id is missing.
    # @return [nil]
    def write_assertions(body = {})
      opts = body[:opts] || {}
      sid = store_id(opts)
      model_id = authorization_model_id(opts)
      fail MissingAuthorizationModelIdError unless model_id

      request_body = WriteAssertionsRequest.new(assertions: body[:assertions])

      with_request_metrics(
        method_name: 'WriteAssertions',
        extra_attrs: {
          Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid,
          Telemetry::Attributes::FGA_CLIENT_REQUEST_MODEL_ID => model_id
        }
      ) do
        @api_client.write_assertions_with_http_info(sid, model_id, request_body, wrap_options(opts))
      end
    end

    # Writes an authorization model for a specific store.
    # Creates or updates the authorization model with provided type definitions, schema version, and conditions.
    # @param body [Hash] The request body containing:
    #   - :type_definitions [Array<TypeDefinition>] Type definitions for the authorization model.
    #   - :schema_version [String] Schema version for the authorization model.
    #   - :conditions [Hash] Conditions for the authorization model.
    #   - :opts [Hash] Optional parameters:
    #       - :store_id [String] Store ID (required if not set in client config).
    # @return [WriteAuthorizationModelResponse] The response with the created or updated authorization model details.
    def write_authorization_model(body = {})
      opts = body[:opts] || {}
      request_body = WriteAuthorizationModelRequest.new(
        type_definitions: body[:type_definitions],
        schema_version: body[:schema_version],
        conditions: body[:conditions]
      )

      sid = store_id(opts)
      with_request_metrics(
        method_name: 'WriteAuthorizationModel',
        extra_attrs: { Telemetry::Attributes::FGA_CLIENT_REQUEST_STORE_ID => sid }
      ) do
        @api_client.write_authorization_model_with_http_info(sid, request_body, wrap_options(opts))
      end
    end

    # Executes a raw API request against the FGA server with automatic auth injection.
    # @param method [String, Symbol] HTTP method (e.g. :get, :post)
    # @param path [String] URL path template (e.g. '/stores/{store_id}/check')
    # @param path_params [Hash] Values for {placeholder} substitution
    # @param query_params [Hash] URL query parameters
    # @param body [Hash, nil] Request body (JSON-serialized automatically)
    # @param headers [Hash] Additional request headers
    # @return [ApiExecutorResponse]
    def execute_api_request(method:, path:, path_params: {}, query_params: {}, body: nil, headers: {})
      request = ApiExecutorRequest.new(
        method:,
        path:,
        path_params:,
        query_params:,
        body:,
        headers:
      )
      request.validate!

      resolved_path = substitute_path_params(request.path, request.path_params)
      merged_headers = build_auth_headers.merge(request.headers)

      opts = {
        header_params: merged_headers,
        query_params:  request.query_params,
        body:          request.body,
        return_type:   'Object'
      }

      data, status, response_headers = @api_client.api_client.call_api(request.method, resolved_path, opts)
      ApiExecutorResponse.new(data:, status:, headers: response_headers)
    end

    private

      # Executes a single batch check and returns [data, status_code, headers]
      def execute_single_batch_check_with_info(checks, opts)
        check_items = build_check_items(checks)
        request_body = build_batch_request(check_items, opts)
        @api_client.batch_check_with_http_info(store_id(opts), request_body, wrap_options(opts))
      end

      # Executes a single batch check and returns just data (used in concurrent batching)
      def execute_single_batch_check(checks, opts)
        data, _status_code, _headers = execute_single_batch_check_with_info(checks, opts)
        data
      end

      # Processes multiple batches concurrently using concurrent-ruby thread pool and futures
      def process_batches_concurrently(batches, max_concurrent, opts)
        # Use concurrent-ruby's thread pool for better performance and resource management
        pool = Concurrent::FixedThreadPool.new(max_concurrent)

        begin
          # Create futures for each batch
          futures = batches.map do |batch|
            Concurrent::Future.execute(executor: pool) do
              execute_single_batch_check(batch, opts)
            rescue => e
              # Log error but don't fail entire operation
              warn "Batch check failed: #{e.message}"
              # Return empty result for this batch
              BatchCheckResponse.new(result: {})
            end
          end

          # Wait for all futures to complete and collect results
          futures.map(&:value!)
        ensure
          # Shutdown the thread pool
          pool.shutdown
          pool.wait_for_termination
        end
      end

      # Builds check items from the check array
      def build_check_items(checks)
        checks.map do |check|
          tuple_key = CheckRequestTupleKey.new({
                                                 user: check[:tuple_key][:user],
                                                 relation: check[:tuple_key][:relation].to_s,
                                                 object: check[:tuple_key][:object]
                                               })

          batch_check_item = BatchCheckItem.new({
                                                  tuple_key:,
                                                  correlation_id: check[:correlation_id].to_s
                                                })

          # Add contextual tuples if provided
          if check.include?(:contextual_tuples)
            contextual_tuples = check[:contextual_tuples]
            tuple_keys = contextual_tuples[:tuple_keys].map { |tk| TupleKey.new(tk) }
            batch_check_item.contextual_tuples = ContextualTupleKeys.new(tuple_keys:)
          end

          # Add context if provided
          if check.include?(:context)
            batch_check_item.context = check[:context]
          end

          batch_check_item
        end
      end

      # Builds the batch check request with options
      def build_batch_request(check_items, opts)
        request_body = BatchCheckRequest.new({ checks: check_items })

        if opts.include?(:authorization_model_id)
          request_body.authorization_model_id = opts[:authorization_model_id]
        end

        if opts.include?(:consistency)
          request_body.consistency = opts[:consistency]
        end

        request_body
      end

      # Returns the store ID from the options or configuration.
      # Raises MissingStoreIdError if the store ID is not provided.
      # @param opts [Hash, nil] Optional parameters that may include :store_id.
      # @return [String] The store ID.
      def store_id(opts = nil)
        id = (opts || {})[:store_id] || @config[:store_id]
        fail MissingStoreIdError unless id
        id
      end

      # Returns the authorization model ID from the options or configuration.
      # @param opts [Hash, nil] Optional parameters that may include :authorization_model_id.
      # @return [String] The authorization model ID.
      def authorization_model_id(opts = nil)
        (opts || {})[:authorization_model_id] || @config[:authorization_model_id]
      end

      # Validates the telemetry configuration passed in the client config.
      # Accepts a Telemetry::Configuration instance or nil (which falls back to
      # the global Telemetry.configuration). Any other type is a misconfiguration.
      # @param telemetry_config [Telemetry::Configuration, nil]
      # @raise [ConfigurationError] If a value of the wrong type is provided.
      # @return [Telemetry::Configuration, nil]
      def resolve_telemetry_config(telemetry_config)
        return nil if telemetry_config.nil?
        return telemetry_config if telemetry_config.is_a?(Telemetry::Configuration)

        raise ConfigurationError,
              'config[:telemetry] must be an OpenFga::Telemetry::Configuration, ' \
              "got #{telemetry_config.class}. Build one with OpenFga::Telemetry::Configuration.new."
      end

      # Returns the options that are augmented with other options that are consistant across
      # all methods and API calls, such as authorization headers.
      # @param opts [Hash, nil] The options
      # @return [Hash] The same options merged with any additional consistant options for all API calls.
      def wrap_options(opts)
        # include authz headers
        (opts || {}).merge(header_params: build_auth_headers)
      end

      def build_auth_headers
        token = @token_manager.access_token

        return {} unless token

        {
          'Authorization' => "Bearer #{token}"
        }
      end

      def substitute_path_params(path, path_params)
        path.gsub(/\{(\w+)\}/) do
          key = $1
          value = path_params[key] || path_params[key.to_sym]
          value ? CGI.escape(value.to_s) : "{#{key}}"
        end
      end

      def new_logger(config)
        logger = Logger.new($stdout)
        logger.level = Logger::INFO

        config[:logger] || (defined?(Rails) ? Rails.logger : logger)
      end

      # Times an API call and records request metrics for both successful and
      # failed responses, then returns the response data. When the API call
      # raises an ApiError (any non-2xx response), metrics are still recorded
      # using the error's status code and headers before the error is re-raised,
      # so failures are observable (e.g. error-rate dashboards).
      #
      # @param method_name [String] The FGA method name (e.g. 'Check').
      # @param extra_attrs [Hash] Additional telemetry attributes for this call.
      # @yield The API call, expected to return [data, status_code, headers].
      # @return [Object] The response data returned by the block.
      def with_request_metrics(method_name:, extra_attrs: {})
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        begin
          data, status_code, headers = yield
        rescue ApiError => e
          record_request_metrics(
            method_name:,
            status_code: e.code,
            headers: e.response_headers,
            started_at:,
            extra_attrs:
          )
          raise
        end

        record_request_metrics(method_name:, status_code:, headers:, started_at:, extra_attrs:)
        data
      end

      def record_request_metrics(method_name:, status_code:, headers:, started_at:, extra_attrs: {})
        duration_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000

        attrs = base_telemetry_attrs(method_name).merge(extra_attrs)
        attrs[Telemetry::Attributes::HTTP_RESPONSE_STATUS_CODE] = status_code.to_s if status_code

        if headers
          resp_model_id = headers[Telemetry::RESPONSE_MODEL_ID_HEADER]
          attrs[Telemetry::Attributes::FGA_CLIENT_RESPONSE_MODEL_ID] = resp_model_id if resp_model_id
        end

        @telemetry_metrics.request_count(1, attrs)
        @telemetry_metrics.request_duration(duration_ms, attrs)

        return unless headers

        query_duration_str = headers[QUERY_DURATION_HEADER_NAME]
        @telemetry_metrics.query_duration(query_duration_str.to_f, attrs) if query_duration_str
      end

      def base_telemetry_attrs(method_name)
        attrs = {
          Telemetry::Attributes::FGA_CLIENT_REQUEST_METHOD => method_name,
          Telemetry::Attributes::USER_AGENT_ORIGINAL       => USER_AGENT
        }

        client_id = @config.dig(:credentials, :client_id)
        attrs[Telemetry::Attributes::FGA_CLIENT_REQUEST_CLIENT_ID] = client_id if client_id

        attrs
      end
  end
end
