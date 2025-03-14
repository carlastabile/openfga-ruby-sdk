require 'json'
require 'pry'

module AuthorizationModelsHelper
  def authorization_model_payload
    file_path = File.join(File.dirname(__FILE__), '../fixtures/authorization_model.json')
    JSON.parse(File.read(file_path))
  end

  def read_authorization_model_response
    file_path = File.join(File.dirname(__FILE__), '../fixtures/read_authorization_model_response.json')
    JSON.parse(File.read(file_path))
  end

  def read_authorization_models_response
    file_path = File.join(File.dirname(__FILE__), '../fixtures/read_authorization_models_response.json')
    JSON.parse(File.read(file_path))
  end
end