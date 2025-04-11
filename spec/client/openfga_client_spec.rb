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

  describe "Authorization Models" do
    let(:subject) { OpenFga::SdkClient.new(api_url: "https://api.example.dev") }
    let(:store_id) { 'JHGFD' }

    context "when writing an authorization model" do
      let(:valid_body){ load_json('write_authorization_model', body: true) }
      let(:invalid_body){ {type_definitions: [] }}
      let(:store_id){ "KJHGFDSUYTREW543GF" }

      # unit tests for write_authorization_model
      # Create a new authorization model
      # The WriteAuthorizationModel API will add a new authorization model to a store. Each item in the &#x60;type_definitions&#x60; array is a type definition as specified in the field &#x60;type_definition&#x60;. The response will return the authorization model&#39;s ID in the &#x60;id&#x60; field.  ## Example To add an authorization model with &#x60;user&#x60; and &#x60;document&#x60; type definitions, call POST authorization-models API with the body:  &#x60;&#x60;&#x60;json {   \&quot;type_definitions\&quot;:[     {       \&quot;type\&quot;:\&quot;user\&quot;     },     {       \&quot;type\&quot;:\&quot;document\&quot;,       \&quot;relations\&quot;:{         \&quot;reader\&quot;:{           \&quot;union\&quot;:{             \&quot;child\&quot;:[               {                 \&quot;this\&quot;:{}               },               {                 \&quot;computedUserset\&quot;:{                   \&quot;object\&quot;:\&quot;\&quot;,                   \&quot;relation\&quot;:\&quot;writer\&quot;                 }               }             ]           }         },         \&quot;writer\&quot;:{           \&quot;this\&quot;:{}         }       }     }   ] } &#x60;&#x60;&#x60; OpenFGA&#39;s response will include the version id for this authorization model, which will look like  &#x60;&#x60;&#x60; {\&quot;authorization_model_id\&quot;: \&quot;01G50QVV17PECNVAHX1GG4Y5NC\&quot;} &#x60;&#x60;&#x60;
      # @param store_id
      # @param body
      # @param [Hash] opts the optional parameters
      # @return [WriteAuthorizationModelResponse]
      it 'creates an authorization model successfully' do
        stub_request_with_response(method: :post,
                                   path: "http://api.example.dev/stores/#{store_id}/authorization-models",
                                   status: 201,
                                   request_body: valid_body,
                                   response_body: { authorization_model_id: "01G50QVV17PECNVAHX1GG4Y5NC" })

        response = subject.write_authorization_model(store_id, valid_body)
        expect(response).to be_a(OpenFga::WriteAuthorizationModelResponse)
        expect(response.authorization_model_id).not_to be_nil
      end

      it 'raises an error for invalid authorization model request' do
        stub_request_with_response(method: :post,
                                   path: "http://api.example.dev/stores/#{store_id}/authorization-models",
                                   status: 400,
                                   request_body: invalid_body,
                                   response_body: {
                                     "code": "validation_error",
                                     "message": "Generic validation error"
                                   })

        expect { subject.write_authorization_model(store_id, invalid_body) }.to(raise_error(OpenFga::ApiError))
      end

      it 'raises an error if store_id is missing' do
        stub_request_with_response(method: :post,
                                   path: "http://api.example.dev/stores/#{store_id}/authorization-models",
                                   status: 400)
        expect { subject.write_authorization_model(nil, valid_body) }.to raise_error(ArgumentError)
      end

      it 'raises an error if body is missing' do
        stub_request_with_response(method: :post,
                                   path: "http://api.example.dev/stores/#{store_id}/authorization-models",
                                   status: 400)
        expect { subject.write_authorization_model(store_id, nil) }.to raise_error(ArgumentError)
      end
    end

    context "when reading an authorization model" do
      let(:model_id) { '01G5JAVJ41T49E9TT3SKVS7X1J' }
      let(:valid_response){ load_json('read_authorization_model') }
      # unit tests for read_authorization_model
      # Return a particular version of an authorization model
      # The ReadAuthorizationModel API returns an authorization model by its identifier. The response will return the authorization model for the particular version.  ## Example To retrieve the authorization model with ID &#x60;01G5JAVJ41T49E9TT3SKVS7X1J&#x60; for the store, call the GET authorization-models by ID API with &#x60;01G5JAVJ41T49E9TT3SKVS7X1J&#x60; as the &#x60;id&#x60; path parameter.  The API will return: &#x60;&#x60;&#x60;json {   \&quot;authorization_model\&quot;:{     \&quot;id\&quot;:\&quot;01G5JAVJ41T49E9TT3SKVS7X1J\&quot;,     \&quot;type_definitions\&quot;:[       {         \&quot;type\&quot;:\&quot;user\&quot;       },       {         \&quot;type\&quot;:\&quot;document\&quot;,         \&quot;relations\&quot;:{           \&quot;reader\&quot;:{             \&quot;union\&quot;:{               \&quot;child\&quot;:[                 {                   \&quot;this\&quot;:{}                 },                 {                   \&quot;computedUserset\&quot;:{                     \&quot;object\&quot;:\&quot;\&quot;,                     \&quot;relation\&quot;:\&quot;writer\&quot;                   }                 }               ]             }           },           \&quot;writer\&quot;:{             \&quot;this\&quot;:{}           }         }       }     ]   } } &#x60;&#x60;&#x60; In the above example, there are 2 types (&#x60;user&#x60; and &#x60;document&#x60;). The &#x60;document&#x60; type has 2 relations (&#x60;writer&#x60; and &#x60;reader&#x60;).
      # @param store_id
      # @param id
      # @param [Hash] opts the optional parameters
      # @return [ReadAuthorizationModelResponse]
      it 'returns the authorization model successfully' do
        stub_request_with_response(method: :get,
                                   path: "http://api.example.dev/stores/#{store_id}/authorization-models/#{model_id}",
                                   status: 200,
                                   response_body: valid_response)
        result = subject.read_authorization_model(store_id, model_id)
        expect(result).to be_a(OpenFga::ReadAuthorizationModelResponse)
        expect(result.authorization_model.id).to eq(model_id)
      end

      it 'raises an error if store_id is missing' do
        expect { subject.read_authorization_model(nil, model_id) }.to raise_error(ArgumentError)
      end

      it 'raises an error if model_id is missing' do
        expect { subject.read_authorization_model(store_id, nil) }.to raise_error(ArgumentError)
      end

      it 'raises an error if the authorization model does not exist' do
        stub_request_with_response(method: :get,
                                   path: "http://api.example.dev/stores/#{store_id}/authorization-models/#{model_id}",
                                   status: 404,
                                   response_body: {
                                     "code": "undefined_endpoint",
                                     "message": "Endpoint not enabled"
                                   })
        expect { subject.read_authorization_model(store_id, model_id) }.to(raise_error)
      end
    end

    context "when listing authorization models" do
      let(:valid_response){ load_json('read_authorization_models') }
      it 'returns authorization models successfully' do
        stub_request_with_response(method: :get,
                                   path: "http://api.example.dev/stores/#{store_id}/authorization-models",
                                   status: 200,
                                   response_body: valid_response)
        result = subject.read_authorization_models(store_id)
        expect(result).to be_a(OpenFga::ReadAuthorizationModelsResponse)
      end

      it 'raises an error if store_id is missing' do
        expect { subject.read_authorization_models(nil) }.to raise_error(ArgumentError)
      end

      it 'raises an error' do
        stub_request_with_response(method: :get,
                                   path: "http://api.example.dev/stores/#{store_id}/authorization-models",
                                   status: 400)
        expect { subject.read_authorization_models(store_id) }.to raise_error(OpenFga::ApiError)
      end
    end
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
