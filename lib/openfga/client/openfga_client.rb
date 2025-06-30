# frozen_string_literal: true

module OpenFga
  class SdkClient
    def initialize(config = {})
      raise ConfigurationNilError.new(:api_url) unless config[:api_url]

      @config = config
      
      api_client_config = Configuration.new do |c|
        c.server_index = nil
        c.host = @config[:api_url]
      end

      @api_client = OpenFga::OpenFgaApi.new(ApiClient.new api_client_config)
    end

    # Create a store
    # Create a unique OpenFGA store which will be used to store authorization models and relationship tuples.
    # @param name [String]
    # @param [Hash] opts the optional parameters
    # @return [CreateStoreResponse]
    def create_store(name, opts = {})
      body = OpenFga::CreateStoreRequest.new(name:)
      @api_client.create_store(body, opts)
    end

    # Delete a store
    # Delete an OpenFGA store. This does not delete the data associated with the store, like tuples or authorization models.
    # @param store_id [String]
    # @param [Hash] opts the optional parameters
    # @return [nil]
    def delete_store(store_id, opts = {})
      @api_client.delete_store(store_id, opts)
    end

    # Get a store
    # Returns an OpenFGA store by its identifier
    # @param store_id [String]
    # @param [Hash] opts the optional parameters
    # @return [GetStoreResponse]
    def get_store(store_id, opts = {})
      @api_client.get_store(store_id, opts)
    end

    # List all stores
    # Returns a paginated list of OpenFGA stores and a continuation token to get additional stores. The continuation token will be empty if there are no more stores.
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :page_size
    # @option opts [String] :continuation_token
    # @return [ListStoresResponse]
    def list_stores(opts = {})
      @api_client.list_stores(opts)
    end

    # Writes an authorization model
    # Creates or updates an authorization model for a specific store.
    #
    # @param store_id [String] The ID of the store where the authorization model will be written.
    # @param body [WriteAuthorizationModelRequest] The request body containing the authorization model details.
    # @param opts [Hash] Optional parameters for the request.
    # @return [WriteAuthorizationModelResponse] The response from the API after writing the authorization model.
    def write_authorization_model(store_id, body, opts = {})
      @api_client.write_authorization_model(store_id, body, opts)
    end

    # Reads an authorization model
    # Retrieves a specific authorization model by its ID from a given store.
    # @param store_id [String] The ID of the store from which to read the authorization model.
    # @param id [String] The ID of the authorization model to read.
    # @param opts [Hash] Optional parameters for the request.
    # @raise [ArgumentError] If the `store_id` or `id` is not provided.
    # @return [ReadAuthorizationModelResponse] The response containing the authorization model details.
    def read_authorization_model(store_id, id, opts = {})
      @api_client.read_authorization_model(store_id, id, opts)
    end

    # Reads all authorization models
    # Retrieves all authorization models for a specific store.
    # @param store_id [String] The ID of the store from which to read the authorization models.
    # @param opts [Hash] Optional parameters for the request.
    # @raise [ArgumentError] If the `store_id` is not provided.
    # @return [ReadAuthorizationModelsResponse] The response containing the list of authorization models.
    def read_authorization_models(opts = {})
      @api_client.read_authorization_models(store_id(opts), opts)
    end

    # Checks whether a specific relationship exists in the store.
    #
    # @param store_id [String] The ID of the store where the check is performed.
    # @param user [String] The user involved in the relationship.
    # @param relation [String, Symbol] The relation to check (e.g., "reader", "owner").
    # @param object [String] The object involved in the relationship.
    # @param opts [Hash] Optional parameters for the check.
    #   @option opts [Hash] :contextual_tuples Additional contextual tuples to include in the check.
    #   @option opts [String] :authorization_model_id The ID of the authorization model to use for the check.
    #   @option opts [Hash] :context Additional context for the check.
    #
    # @raise [ArgumentError] If any of the required parameters (`user`, `relation`, or `object`) are missing.
    #
    # @return [CheckResponse] The result of the check operation.
    def check(user:, relation:, object:, opts: {})
      fail ArgumentError, "Missing the required parameter 'user'" if user.nil?
      fail ArgumentError, "Missing the required parameter 'relation'" if relation.nil?
      fail ArgumentError, "Missing the required parameter 'object'" if object.nil?

      tuple_key = CheckRequestTupleKey.new({
        user:, relation: relation.to_s, object: })

      request_body = CheckRequest.new({ tuple_key: })

      if opts.include?(:contextual_tuples)
        contextual_tuples = opts[:contextual_tuples]
        tuple_keys = contextual_tuples[:tuple_keys].map { |tuple_key| TupleKey.new(tuple_key) }
        request_body.contextual_tuples = ContextualTupleKeys.new(tuple_keys:)
      end

      if opts.include?(:authorization_model_id)
        request_body.authorization_model_id = opts[:authorization_model_id]
      end

      if opts.include?(:context)
        request_body.context = opts[:context]
      end

      @api_client.check(store_id(opts), request_body, opts)
    end

    # Read changes
    # Reads the list of historical relationship tuple writes and deletes.
    # @param [Hash] body The request body
    # @option body [String] :start_time The start time of the range to read changes from. This is a timestamp in ISO 8601 format.
    # @option body [String] :type Get the list of tuple changes that affect only this type
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :page_size The number of pages to return in the request
    # @option opts [String] :continuation_token The continuation token to use to get the next page of results. This will be empty if there are no more results.
    # @option opts [String] :store_id The store ID to read changes from
    def read_changes(body = {}, opts = {})
      fail ArgumentError, "Missing the required parameter 'body'" if body.nil?

      # the underlying client has an allowlist of parameters, so no need to
      # strip out `store_id` from the body.
      @api_client.read_changes(store_id(opts), opts.merge(body))
    end

    # GET /stores/{store_id}/assertions/{authorization_model_id}
    # Retrieve assertions for a specific store and authorization model
    # @param [Hash] opts The optional parameters
    # @return [GetAssertionsResponse]
    def read_assertions(opts = {})
      @api_client.read_assertions(store_id(opts), authorization_model_id(opts), opts)
    end

    # PUT /stores/{store_id}/assertions/{authorization_model_id}
    # Update assertions for a specific store and authorization model
    # @param body [UpdateAssertionsRequest] The request body containing the assertions
    # @param [Hash] opts The optional parameters
    # @return [nil]
    def write_assertions(body = {}, opts = {})
      fail ArgumentError, "Missing the required parameter 'body'" if body.nil?

      request_body = WriteAssertionsRequest.new(body)

      @api_client.write_assertions(store_id(opts), authorization_model_id(opts), request_body, opts)
    end

    # Read tuples
    # Reads tuples from the store.
    # @param [Hash] body The request body
    # @option body [String] :user The user to read tuples for
    # @option body [String] :relation The relation to read tuples for
    # @option body [String] :object The object to read tuples for
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :page_size The number of pages to return in the request
    # @option opts [String] :continuation_token The continuation token to use to get the next page of results. This will be empty if there are no more results.
    # @option opts [String] :store_id The store ID to read changes from
    def read(body = {}, opts = {})
      fail ArgumentError, "Missing the required parameter 'body'" if body.nil?

      request_body = ReadRequest.new(
        continuation_token: opts[:continuation_token],
        page_size: opts[:page_size] || 50,
        tuple_key: {
          user: body[:user],
          relation: body[:relation].to_s,
          object: body[:object]
        },
        consistency: opts[:consistency])

      @api_client.read(store_id(opts), request_body, opts)
    end

    private
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
      # Raises MissingAuthorizationModelIdError if the authorization model ID is not provided.
      # @param opts [Hash, nil] Optional parameters that may include :authorization_model_id.
      # @return [String] The authorization model ID.
      def authorization_model_id(opts = nil)
        id = (opts || {})[:authorization_model_id] || @config[:authorization_model_id]
        fail MissingAuthorizationModelIdError unless id
        id
      end
  end
end
