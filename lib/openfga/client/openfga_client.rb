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
      body = OpenFga::CreateStoreRequest.new(name: name)
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
  end
end
