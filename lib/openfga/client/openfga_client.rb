# frozen_string_literal: true

module OpenFga
  class SdkClient
    def initialize(config = {})
      raise ConfigurationNilError.new(:api_url) unless config[:api_url]

      @config = config
      
      api_client_config = Configuration.new do |c|
        c.server_index = nil
        c.host = @config[:api_url]

        if @config[:stubs]
          c.configure_faraday_connection do |f|
            f.adapter :test, @config[:stubs]
          end
        end
      end

      @api_client = OpenFga::OpenFgaApi.new(ApiClient.new api_client_config)
    end

    def list_stores
      @api_client.list_stores
    end
  end
end
