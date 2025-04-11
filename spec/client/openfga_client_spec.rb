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

  describe "Stores" do
    let(:subject) { OpenFga::SdkClient.new(api_url: "https://api.example.dev") }

    # unit tests for create_store
    # Create a store
    # Create a unique OpenFGA store which will be used to store authorization models and relationship tuples.
    # @param name [String]
    # @param [Hash] opts the optional parameters
    # @return [CreateStoreResponse]
    context 'when creating a store' do
      let(:store_attributes) { { id: 'JHGFD', name: 'new_store', created_at: DateTime.now, updated_at: DateTime.now } }

      it 'creates a store successfully' do
        stub_request_with_response(method: :post,
                                   path: "http://api.example.dev/stores",
                                   status: 200,
                                   request_body: { name: "new_store"},
                                   response_body: store_attributes)

        response = subject.create_store('new_store')

        expect(response).to be_instance_of(OpenFga::CreateStoreResponse)
        expect(response.id).to eq('JHGFD')
      end

      it 'raises an error for invalid store creation request' do
        stub_request_with_response(method: :post,
                                   path: "http://api.example.dev/stores",
                                   status: 400,
                                   request_body: { name: ""},
                                   response_body: { code: "validation_error",
                                                    message: "Generic validation error" })

        expect { subject.create_store('') }.to raise_error(OpenFga::ApiError)
      end
    end

    # unit tests for delete_store
    # Delete a store
    # Delete an OpenFGA store. This does not delete the data associated with the store, like tuples or authorization models.
    # @param store_id
    # @param [Hash] opts the optional parameters
    # @return [nil]
    describe 'when deleting a store' do
      it 'should delete store successfully' do
        stub_request_with_response(method: :delete,
                                   path: "http://api.example.dev/stores/JHGFD",
                                   status: 204)
        expect(subject.delete_store('JHGFD')).to be_nil
      end

      it "should raise an error id no store_id is set" do
        expect { subject.delete_store(nil) }.to raise_error(ArgumentError)
      end

      it "should raise an error " do
        stub_request_with_response(method: :delete,
                                   path: "http://api.example.dev/stores/JHGFD",
                                   status: 400,
                                   response_body: { code: "validation_error",
                                                    message: "Generic validation error" })
        expect { subject.delete_store('JHGFD') }.to raise_error(OpenFga::ApiError)
      end
    end

    # unit tests for get_store
    # Get a store
    # Returns an OpenFGA store by its identifier
    # @param store_id
    # @param [Hash] opts the optional parameters
    # @return [GetStoreResponse]
    describe 'when getting a store' do
      let(:store_attributes) { { id: 'JHGFD', name: 'new_store', created_at: DateTime.now, updated_at: DateTime.now } }

      it 'should get a store successfully' do
        stub_request_with_response(method: :get,
                                   path: "http://api.example.dev/stores/JHGFD",
                                   status: 200,
                                   response_body: store_attributes)
        response = subject.get_store('JHGFD')
        expect(response).to be_instance_of(OpenFga::GetStoreResponse)
        expect(response.id).to eq('JHGFD')
      end

      it "should raise an error id no store_id is set" do
        expect { subject.get_store(nil) }.to raise_error(ArgumentError)
      end

      it "should raise an error " do
        stub_request_with_response(method: :get,
                                   path: "http://api.example.dev/stores/JHGFD",
                                   status: 400)
        expect { subject.get_store('JHGFD') }.to raise_error(OpenFga::ApiError)
      end
    end

    # unit tests for list_stores
    #   List all stores
    #   Returns a paginated list of OpenFGA stores and a continuation token to get additional stores. The continuation token will be empty if there are no more stores.
    #   @param [Hash] opts the optional parameters
    #   @option opts [Integer] :page_size
    #   @option opts [String] :continuation_token
    #   @return [ListStoresResponse]
    describe 'when listing stores' do
      let(:store_attributes) { { id: 'JHGFD', name: 'new_store', created_at: DateTime.now, updated_at: DateTime.now } }

      it 'should list stores successfully' do
        stub_request_with_response(method: :get,
                                   path: "http://api.example.dev/stores",
                                   status: 200,
                                   response_body: { stores: [store_attributes],
                                                    continuation_token: "eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ"})
        response = subject.list_stores
        expect(response).to be_instance_of(OpenFga::ListStoresResponse)
        expect(response.stores[0].id).to eq('JHGFD')
      end

      it "should raise an error " do
        stub_request_with_response(method: :get,
                                   path: "http://api.example.dev/stores",
                                   status: 400)
        expect { subject.list_stores }.to raise_error(OpenFga::ApiError)
      end
    end
  end
end
