module OpenFga
  class Client 
    attr_accessor :openfga_api

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end
  end 
end