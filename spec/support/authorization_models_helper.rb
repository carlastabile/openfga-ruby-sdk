require 'json'

module AuthorizationModelsHelper
  def authorization_model
    file_path = File.join(File.dirname(__FILE__), '../fixtures/authorization_models_fixtures.json')
    JSON.parse(File.read(file_path))
  end
end