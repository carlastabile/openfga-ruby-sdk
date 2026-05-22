# frozen_string_literal: true

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

      @logger = config[:logger] || (defined?(Rails) ? Rails.logger : Logger.new($stdout))

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

                         TokenManager::Oauth2TokenManager.new(oauth_config)
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
      end

      @api_client = OpenFga::OpenFgaApi.new(ApiClient.new(api_client_config))
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

      # If we have fewer checks than the batch limit, use simple approach
      if checks.length <= max_batch_size
        return execute_single_batch_check(checks, opts)
      end

      # Split checks into batches and process concurrently
      check_batches = checks.each_slice(max_batch_size).to_a
      all_results = process_batches_concurrently(check_batches, max_parallel_requests, opts)

      # Merge all batch results
      merged_results = {}
      all_results.each do |batch_response|
        if batch_response&.result
          merged_results.merge!(batch_response.result)
        end
      end

      # Return a BatchCheckResponse with merged results
      BatchCheckResponse.new(result: merged_results)
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

      @api_client.check(store_id(opts), request_body, wrap_options(opts))
    end

    ## Creates a new OpenFGA store for storing authorization models and relationship tuples.
    # @param body [Hash] The request body with store details.
    #   - :name [String] The name of the store to create.
    #   - :opts [Hash] Optional parameters for the request.
    # @return [CreateStoreResponse] The response with the created store details.
    def create_store(body = {})
      request_body = OpenFga::CreateStoreRequest.new(body)
      opts = body[:opts] || {}

      @api_client.create_store(request_body, wrap_options(opts))
    end

    # Delete a store
    # Delete an OpenFGA store.
    # @param opts [Hash] Optional parameters for the request
    # @option opts [String] :store_id The ID of the store to delete (required if not set in client config)
    # @return [nil]
    def delete_store(opts = {})
      @api_client.delete_store(store_id(opts), wrap_options(opts))
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

      # Call the API client to perform the expansion
      @api_client.expand(store_id(opts), request_body, wrap_options(opts))
    end

    # Get a store
    # Returns an OpenFGA store by its identifier
    # @param opts [Hash] Optional parameters for the request
    # @option opts [String] :store_id The ID of the store to retrieve (required if not set in client config)
    # @return [GetStoreResponse] The response containing the store details
    def get_store(opts = {})
      @api_client.get_store(store_id(opts), wrap_options(opts))
    end

    # Get a store
    # Returns an OpenFGA store by its identifier
    # @param opts [Hash] Optional parameters for the request
    # @option opts [String] :store_id The ID of the store to retrieve (required if not set in client config)
    # @return [GetStoreResponse] The response containing the store details
    def get_store(opts = {})
      @api_client.get_store(store_id(opts), wrap_options(opts))
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

      # Call the API client to perform the list objects request
      @api_client.list_objects(store_id(opts), request_body, wrap_options(opts))
    end

    # List all stores
    # Returns a paginated list of OpenFGA stores and a continuation token to get additional stores. The continuation token will be empty if there are no more stores.
    # @param opts [Hash] Optional parameters for the request
    # @option opts [Integer] :page_size The number of stores to return per page
    # @option opts [String] :continuation_token The continuation token for pagination
    # @return [ListStoresResponse] The response containing the paginated list of stores
    def list_stores(opts = {})
      @api_client.list_stores(wrap_options(opts))
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

      @api_client.list_users(store_id(opts), request_body, wrap_options(opts))
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

      @api_client.read(store_id(opts), request_body, wrap_options(opts))
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
      @api_client.read_assertions(store_id(opts), authorization_model_id(opts), wrap_options(opts))
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
      @api_client.read_authorization_model(store_id(opts), authorization_model_id(opts), wrap_options(opts))
    end

    # Read all authorization models
    # Retrieves all authorization models for a specific store.
    # @param opts [Hash] Optional parameters for the request
    # @option opts [String] :store_id The ID of the store (required if not set in client config)
    # @raise [MissingStoreIdError] If the store_id is not provided
    # @return [ReadAuthorizationModelsResponse] The response containing the list of authorization models
    def read_authorization_models(opts = {})
      @api_client.read_authorization_models(store_id(opts), wrap_options(opts))
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
      @api_client.read_changes(store_id(opts), wrap_options(opts))
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
      @api_client.write(store_id(opts), request_body, wrap_options(opts))
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
      store_id = store_id(opts)
      model_id = authorization_model_id(opts)
      fail MissingAuthorizationModelIdError unless model_id

      request_body = WriteAssertionsRequest.new(assertions: body[:assertions])

      @api_client.write_assertions(store_id, model_id, request_body, wrap_options(opts))
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

      @api_client.write_authorization_model(store_id(opts), request_body, wrap_options(opts))
    end

    private

      # Executes a single batch check (used when no splitting is needed)
      def execute_single_batch_check(checks, opts)
        check_items = build_check_items(checks)
        request_body = build_batch_request(check_items, opts)
        @api_client.batch_check(store_id(opts), request_body, wrap_options(opts))
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
  end
end
