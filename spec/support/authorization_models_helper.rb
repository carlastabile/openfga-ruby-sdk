require 'json'
require 'pry'

module AuthorizationModelsHelper
  def load_json(endpoint_name, body: false)
    suffix = body ? 'body' : 'response'
    file_path = File.join(File.dirname(__FILE__), "../fixtures/#{endpoint_name}_#{suffix}.json")
    JSON.parse(File.read(file_path))
  end
end
