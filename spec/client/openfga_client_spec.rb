require 'spec_helper'

describe OpenFga::SdkClient do
  let(:api_url) { 'http://localhost:8090' }

  describe 'Configuration errors' do
    it 'checks for api_url' do
      expect { OpenFga::SdkClient.new }.to raise_error(ConfigurationNilError) do |err|
        expect(err.property).to be :api_url
      end
    end
  end

  it 'can create a client with basic options' do
    expect(OpenFga::SdkClient.new(api_url:)).not_to be_nil
  end

  describe 'stores API' do
    let(:stubs) { Faraday::Adapter::Test::Stubs.new }
    subject { OpenFga::SdkClient.new(api_url:, stubs:) }

    it 'can list stores' do
      response = <<-JSON
      {
        "stores": [
          {
            "id": "01JQPA9D1Q753B32CKCAQ38Q28",
            "name": "Test store 1",
            "created_at": "2025-03-31T00:00:00Z",
            "updated_at": "2025-03-31T00:00:00Z"
          }
        ],
        "continuation_token": "01JQPB4PY93T7N8QVB6KGCC464"
      }
      JSON

      stubs.get('/stores') { |env| [200, { 'content-type': 'application/json' }, response] }
      expect(subject.list_stores.stores).not_to be_empty
    end
  end
end
