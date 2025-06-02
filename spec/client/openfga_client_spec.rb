require 'spec_helper'

describe OpenFga::SdkClient do
  let(:api_url) { 'http://localhost:8090' }
  let(:store_id) { '01JSKYVY76JYW2DG65NG1444T4' }
  let(:subject) { OpenFga::SdkClient.new(api_url:) }

  def store_path(store_id)
    "/stores/#{store_id}"
  end

  def stores_url(store_id = nil)
    return "#{api_url}#{store_path(store_id)}" if store_id
    "#{api_url}/stores"
  end

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

  describe 'Authorization Models' do
    context 'when writing an authorization model' do
      let(:valid_body) { load_json('write_authorization_model', body: true) }
      let(:invalid_body) { { type_definitions: [] } }

      # unit tests for write_authorization_model
      # Create a new authorization model
      # The WriteAuthorizationModel API will add a new authorization model to a store. Each item in the &#x60;type_definitions&#x60; array is a type definition as specified in the field &#x60;type_definition&#x60;. The response will return the authorization model&#39;s ID in the &#x60;id&#x60; field.  ## Example To add an authorization model with &#x60;user&#x60; and &#x60;document&#x60; type definitions, call POST authorization-models API with the body:  &#x60;&#x60;&#x60;json {   \&quot;type_definitions\&quot;:[     {       \&quot;type\&quot;:\&quot;user\&quot;     },     {       \&quot;type\&quot;:\&quot;document\&quot;,       \&quot;relations\&quot;:{         \&quot;reader\&quot;:{           \&quot;union\&quot;:{             \&quot;child\&quot;:[               {                 \&quot;this\&quot;:{}               },               {                 \&quot;computedUserset\&quot;:{                   \&quot;object\&quot;:\&quot;\&quot;,                   \&quot;relation\&quot;:\&quot;writer\&quot;                 }               }             ]           }         },         \&quot;writer\&quot;:{           \&quot;this\&quot;:{}         }       }     }   ] } &#x60;&#x60;&#x60; OpenFGA&#39;s response will include the version id for this authorization model, which will look like  &#x60;&#x60;&#x60; {\&quot;authorization_model_id\&quot;: \&quot;01G50QVV17PECNVAHX1GG4Y5NC\&quot;} &#x60;&#x60;&#x60;
      # @param store_id
      # @param body
      # @param [Hash] opts the optional parameters
      # @return [WriteAuthorizationModelResponse]
      it 'creates an authorization model successfully' do
        stub_request_with_response(method: :post,
                                   path: "#{stores_url(store_id)}/authorization-models",
                                   status: 201,
                                   request_body: valid_body,
                                   response_body: { authorization_model_id: '01G50QVV17PECNVAHX1GG4Y5NC' })

        response = subject.write_authorization_model(store_id, valid_body)
        expect(response).to be_a(OpenFga::WriteAuthorizationModelResponse)
        expect(response.authorization_model_id).not_to be_nil
      end

      it 'raises an error for invalid authorization model request' do
        stub_request_with_response(method: :post,
                                   path: "#{stores_url(store_id)}/authorization-models",
                                   status: 400,
                                   request_body: invalid_body,
                                   response_body: {
                                     code: 'validation_error',
                                     message: 'Generic validation error'
                                   })

        expect { subject.write_authorization_model(store_id, invalid_body) }.to(raise_error(OpenFga::ApiError))
      end

      it 'raises an error if store_id is missing' do
        stub_request_with_response(method: :post,
                                   path: "#{stores_url(store_id)}/authorization-models",
                                   status: 400)
        expect { subject.write_authorization_model(nil, valid_body) }.to raise_error(ArgumentError)
      end

      it 'raises an error if body is missing' do
        stub_request_with_response(method: :post,
                                   path: "#{stores_url(store_id)}/authorization-models",
                                   status: 400)
        expect { subject.write_authorization_model(store_id, nil) }.to raise_error(ArgumentError)
      end
    end

    context 'when reading an authorization model' do
      let(:model_id) { '01G5JAVJ41T49E9TT3SKVS7X1J' }
      let(:valid_response) { load_json('read_authorization_model') }
      # unit tests for read_authorization_model
      # Return a particular version of an authorization model
      # The ReadAuthorizationModel API returns an authorization model by its identifier. The response will return the authorization model for the particular version.  ## Example To retrieve the authorization model with ID &#x60;01G5JAVJ41T49E9TT3SKVS7X1J&#x60; for the store, call the GET authorization-models by ID API with &#x60;01G5JAVJ41T49E9TT3SKVS7X1J&#x60; as the &#x60;id&#x60; path parameter.  The API will return: &#x60;&#x60;&#x60;json {   \&quot;authorization_model\&quot;:{     \&quot;id\&quot;:\&quot;01G5JAVJ41T49E9TT3SKVS7X1J\&quot;,     \&quot;type_definitions\&quot;:[       {         \&quot;type\&quot;:\&quot;user\&quot;       },       {         \&quot;type\&quot;:\&quot;document\&quot;,         \&quot;relations\&quot;:{           \&quot;reader\&quot;:{             \&quot;union\&quot;:{               \&quot;child\&quot;:[                 {                   \&quot;this\&quot;:{}                 },                 {                   \&quot;computedUserset\&quot;:{                     \&quot;object\&quot;:\&quot;\&quot;,                     \&quot;relation\&quot;:\&quot;writer\&quot;                   }                 }               ]             }           },           \&quot;writer\&quot;:{             \&quot;this\&quot;:{}           }         }       }     ]   } } &#x60;&#x60;&#x60; In the above example, there are 2 types (&#x60;user&#x60; and &#x60;document&#x60;). The &#x60;document&#x60; type has 2 relations (&#x60;writer&#x60; and &#x60;reader&#x60;).
      # @param store_id
      # @param id
      # @param [Hash] opts the optional parameters
      # @return [ReadAuthorizationModelResponse]
      it 'returns the authorization model successfully' do
        stub_request_with_response(method: :get,
                                   path: "#{stores_url(store_id)}/authorization-models/#{model_id}",
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
                                   path: "#{stores_url(store_id)}/authorization-models/#{model_id}",
                                   status: 404,
                                   response_body: {
                                     code: 'undefined_endpoint',
                                     message: 'Endpoint not enabled'
                                   })
        expect { subject.read_authorization_model(store_id, model_id) }.to raise_error(OpenFga::ApiError)
      end
    end

    context 'when listing authorization models' do
      let(:valid_response) { load_json('read_authorization_models') }
      it 'returns authorization models successfully' do
        stub_request_with_response(method: :get,
                                   path: "#{stores_url(store_id)}/authorization-models",
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
                                   path: "#{stores_url(store_id)}/authorization-models",
                                   status: 400)
        expect { subject.read_authorization_models(store_id) }.to raise_error(OpenFga::ApiError)
      end
    end
  end

  describe 'Relationship Queries' do
    # unit tests for batch_check
    # Send a list of &#x60;check&#x60; operations in a single request
    # The &#x60;BatchCheck&#x60; API functions nearly identically to &#x60;Check&#x60;, but instead of checking a single user-object relationship BatchCheck accepts a list of relationships to check and returns a map containing &#x60;BatchCheckItem&#x60; response for each check it received.  An associated &#x60;correlation_id&#x60; is required for each check in the batch. This ID is used to correlate a check to the appropriate response. It is a string consisting of only alphanumeric characters or hyphens with a maximum length of 36 characters. This &#x60;correlation_id&#x60; is used to map the result of each check to the item which was checked, so it must be unique for each item in the batch. We recommend using a UUID or ULID as the &#x60;correlation_id&#x60;, but you can use whatever unique identifier you need as long  as it matches this regex pattern: &#x60;^[\\w\\d-]{1,36}$&#x60;  For more details on how &#x60;Check&#x60; functions, see the docs for &#x60;/check&#x60;.  ### Examples #### A BatchCheckRequest &#x60;&#x60;&#x60;json {   \&quot;checks\&quot;: [      {        \&quot;tuple_key\&quot;: {          \&quot;object\&quot;: \&quot;document:2021-budget\&quot;          \&quot;relation\&quot;: \&quot;reader\&quot;,          \&quot;user\&quot;: \&quot;user:anne\&quot;,        },        \&quot;contextual_tuples\&quot;: {...}        \&quot;context\&quot;: {}        \&quot;correlation_id\&quot;: \&quot;01JA8PM3QM7VBPGB8KMPK8SBD5\&quot;      },      {        \&quot;tuple_key\&quot;: {          \&quot;object\&quot;: \&quot;document:2021-budget\&quot;          \&quot;relation\&quot;: \&quot;reader\&quot;,          \&quot;user\&quot;: \&quot;user:bob\&quot;,        },        \&quot;contextual_tuples\&quot;: {...}        \&quot;context\&quot;: {}        \&quot;correlation_id\&quot;: \&quot;01JA8PMM6A90NV5ET0F28CYSZQ\&quot;      }    ] } &#x60;&#x60;&#x60;  Below is a possible response to the above request. Note that the result map&#39;s keys are the &#x60;correlation_id&#x60; values from the checked items in the request: &#x60;&#x60;&#x60;json {    \&quot;result\&quot;: {      \&quot;01JA8PMM6A90NV5ET0F28CYSZQ\&quot;: {        \&quot;allowed\&quot;: false,         \&quot;error\&quot;: {\&quot;message\&quot;: \&quot;\&quot;}      },      \&quot;01JA8PM3QM7VBPGB8KMPK8SBD5\&quot;: {        \&quot;allowed\&quot;: true,         \&quot;error\&quot;: {\&quot;message\&quot;: \&quot;\&quot;}      } } &#x60;&#x60;&#x60;
    # @param store_id
    # @param body
    # @param [Hash] opts the optional parameters
    # @return [BatchCheckResponse]
    describe 'batch_check test' do
      it 'should work' do
        # assertion here. ref: https://rspec.info/features/3-12/rspec-expectations/built-in-matchers/
      end
    end

    # unit tests for check
    # Check whether a user is authorized to access an object
    # The Check API returns whether a given user has a relationship with a given object in a given store. The &#x60;user&#x60; field of the request can be a specific target, such as &#x60;user:anne&#x60;, or a userset (set of users) such as &#x60;group:marketing#member&#x60; or a type-bound public access &#x60;user:*&#x60;. To arrive at a result, the API uses: an authorization model, explicit tuples written through the Write API, contextual tuples present in the request, and implicit tuples that exist by virtue of applying set theory (such as &#x60;document:2021-budget#viewer@document:2021-budget#viewer&#x60;; the set of users who are viewers of &#x60;document:2021-budget&#x60; are the set of users who are the viewers of &#x60;document:2021-budget&#x60;). A &#x60;contextual_tuples&#x60; object may also be included in the body of the request. This object contains one field &#x60;tuple_keys&#x60;, which is an array of tuple keys. Each of these tuples may have an associated &#x60;condition&#x60;. You may also provide an &#x60;authorization_model_id&#x60; in the body. This will be used to assert that the input &#x60;tuple_key&#x60; is valid for the model specified. If not specified, the assertion will be made against the latest authorization model ID. It is strongly recommended to specify authorization model id for better performance. You may also provide a &#x60;context&#x60; object that will be used to evaluate the conditioned tuples in the system. It is strongly recommended to provide a value for all the input parameters of all the conditions, to ensure that all tuples be evaluated correctly. By default, the Check API caches results for a short time to optimize performance. You may specify a value of &#x60;HIGHER_CONSISTENCY&#x60; for the optional &#x60;consistency&#x60; parameter in the body to inform the server that higher conisistency is preferred at the expense of increased latency. Consideration should be given to the increased latency if requesting higher consistency. The response will return whether the relationship exists in the field &#x60;allowed&#x60;.  Some exceptions apply, but in general, if a Check API responds with &#x60;{allowed: true}&#x60;, then you can expect the equivalent ListObjects query to return the object, and viceversa.  For example, if &#x60;Check(user:anne, reader, document:2021-budget)&#x60; responds with &#x60;{allowed: true}&#x60;, then &#x60;ListObjects(user:anne, reader, document)&#x60; may include &#x60;document:2021-budget&#x60; in the response. ## Examples ### Querying with contextual tuples In order to check if user &#x60;user:anne&#x60; of type &#x60;user&#x60; has a &#x60;reader&#x60; relationship with object &#x60;document:2021-budget&#x60; given the following contextual tuple &#x60;&#x60;&#x60;json {   \&quot;user\&quot;: \&quot;user:anne\&quot;,   \&quot;relation\&quot;: \&quot;member\&quot;,   \&quot;object\&quot;: \&quot;time_slot:office_hours\&quot; } &#x60;&#x60;&#x60; the Check API can be used with the following request body: &#x60;&#x60;&#x60;json {   \&quot;tuple_key\&quot;: {     \&quot;user\&quot;: \&quot;user:anne\&quot;,     \&quot;relation\&quot;: \&quot;reader\&quot;,     \&quot;object\&quot;: \&quot;document:2021-budget\&quot;   },   \&quot;contextual_tuples\&quot;: {     \&quot;tuple_keys\&quot;: [       {         \&quot;user\&quot;: \&quot;user:anne\&quot;,         \&quot;relation\&quot;: \&quot;member\&quot;,         \&quot;object\&quot;: \&quot;time_slot:office_hours\&quot;       }     ]   },   \&quot;authorization_model_id\&quot;: \&quot;01G50QVV17PECNVAHX1GG4Y5NC\&quot; } &#x60;&#x60;&#x60; ### Querying usersets Some Checks will always return &#x60;true&#x60;, even without any tuples. For example, for the following authorization model &#x60;&#x60;&#x60;python model   schema 1.1 type user type document   relations     define reader: [user] &#x60;&#x60;&#x60; the following query &#x60;&#x60;&#x60;json {   \&quot;tuple_key\&quot;: {      \&quot;user\&quot;: \&quot;document:2021-budget#reader\&quot;,      \&quot;relation\&quot;: \&quot;reader\&quot;,      \&quot;object\&quot;: \&quot;document:2021-budget\&quot;   } } &#x60;&#x60;&#x60; will always return &#x60;{ \&quot;allowed\&quot;: true }&#x60;. This is because usersets are self-defining: the userset &#x60;document:2021-budget#reader&#x60; will always have the &#x60;reader&#x60; relation with &#x60;document:2021-budget&#x60;. ### Querying usersets with difference in the model A Check for a userset can yield results that must be treated carefully if the model involves difference. For example, for the following authorization model &#x60;&#x60;&#x60;python model   schema 1.1 type user type group   relations     define member: [user] type document   relations     define blocked: [user]     define reader: [group#member] but not blocked &#x60;&#x60;&#x60; the following query &#x60;&#x60;&#x60;json {   \&quot;tuple_key\&quot;: {      \&quot;user\&quot;: \&quot;group:finance#member\&quot;,      \&quot;relation\&quot;: \&quot;reader\&quot;,      \&quot;object\&quot;: \&quot;document:2021-budget\&quot;   },   \&quot;contextual_tuples\&quot;: {     \&quot;tuple_keys\&quot;: [       {         \&quot;user\&quot;: \&quot;user:anne\&quot;,         \&quot;relation\&quot;: \&quot;member\&quot;,         \&quot;object\&quot;: \&quot;group:finance\&quot;       },       {         \&quot;user\&quot;: \&quot;group:finance#member\&quot;,         \&quot;relation\&quot;: \&quot;reader\&quot;,         \&quot;object\&quot;: \&quot;document:2021-budget\&quot;       },       {         \&quot;user\&quot;: \&quot;user:anne\&quot;,         \&quot;relation\&quot;: \&quot;blocked\&quot;,         \&quot;object\&quot;: \&quot;document:2021-budget\&quot;       }     ]   }, } &#x60;&#x60;&#x60; will return &#x60;{ \&quot;allowed\&quot;: true }&#x60;, even though a specific user of the userset &#x60;group:finance#member&#x60; does not have the &#x60;reader&#x60; relationship with the given object. ### Requesting higher consistency By default, the Check API caches results for a short time to optimize performance. You may request higher consistency to inform the server that higher consistency should be preferred at the expense of increased latency. Care should be taken when requesting higher consistency due to the increased latency. &#x60;&#x60;&#x60;json {   \&quot;tuple_key\&quot;: {      \&quot;user\&quot;: \&quot;group:finance#member\&quot;,      \&quot;relation\&quot;: \&quot;reader\&quot;,      \&quot;object\&quot;: \&quot;document:2021-budget\&quot;   },   \&quot;consistency\&quot;: \&quot;HIGHER_CONSISTENCY\&quot; } &#x60;&#x60;&#x60;
    # @param store_id
    # @param body
    # @param [Hash] opts the optional parameters
    # @return [CheckResponse]
    context 'when running a check request' do
      let(:contextual_tuples) do
          { 
            tuple_keys: [
              {
                user: 'user:anne',
                relation: 'writer',
                object: 'document:2021-budget',
                condition: {
                  name: 'condition1',
                  context: {}
                }
              }
            ]
          }
        end

      it 'should work for authorized tuple' do
        stub_request_with_response(method: :post,
                                   path: "#{stores_url(store_id)}/check",
                                   status: 200,
                                   request_body: { tuple_key:
                                                     {
                                                       user: 'user:anne',
                                                       relation: 'reader',
                                                       object: 'document:2021-budget'
                                                     },
                                                   consistency: 'UNSPECIFIED'
                                   },
                                   response_body: { allowed: true, resolution: 'string' })

        response = subject.check(store_id:, user: 'user:anne', relation: :reader, object: 'document:2021-budget')
        expect(response).to be_a(OpenFga::CheckResponse)
        expect(response.allowed).to be true
      end

      it 'should fail for unauthorized tuple' do
        stub_request_with_response(method: :post,
                                   path: "#{stores_url(store_id)}/check",
                                   status: 200,
                                   request_body: { tuple_key:
                                                     {
                                                       user: 'user:anne',
                                                       relation: 'reader',
                                                       object: 'document:2021-budget'
                                                     },
                                                   consistency: 'UNSPECIFIED'
                                   },
                                   response_body: { allowed: false, resolution: 'string' })

        response = subject.check(store_id:, user: 'user:anne', relation: :reader, object: 'document:2021-budget')
        expect(response).to be_a(OpenFga::CheckResponse)
        expect(response.allowed).to be false
      end

      it 'should raise an error if store_id is missing' do
        expect { subject.check(store_id: nil, user: 'user:anne', relation: :reader, object: 'roadmap') }.to raise_error(ArgumentError)
      end

      it 'should raise an error if user is missing' do
        expect { subject.check(store_id:, user: nil, relation: :reader, object: 'roadmap') }.to raise_error(ArgumentError)
      end

      it 'should raise an error if relation is missing' do
        expect { subject.check(store_id:, user: 'user:anne', relation: nil, object: 'roadmap') }.to raise_error(ArgumentError)
      end

      it 'should raise an error if object is missing' do
        expect { subject.check(store_id: nil, user: 'user:anne', relation: :reader, object: nil) }.to raise_error(ArgumentError)
      end

      it 'should work with contextual tuples' do
        stub_request_with_response(method: :post,
                                   path: "#{stores_url(store_id)}/check",
                                   status: 200,
                                   request_body: { tuple_key:
                                                     {
                                                       user: 'user:anne',
                                                       relation: 'reader',
                                                       object: 'document:2021-budget'
                                                     },
                                                   contextual_tuples:,
                                                   consistency: 'UNSPECIFIED'
                                   },
                                   response_body: { allowed: true, resolution: 'string' })

        response = subject.check(store_id:, user: 'user:anne', relation: :reader, object: 'document:2021-budget',
                                 opts: { contextual_tuples: })
        expect(response).to be_a(OpenFga::CheckResponse)
        expect(response.allowed).to be true
      end

      it 'should work with different authorization_model_id' do
        stub_request_with_response(method: :post,
                                   path: "#{stores_url(store_id)}/check",
                                   status: 200,
                                   request_body: {
                                     tuple_key: {
                                       user: 'user:anne',
                                       relation: 'reader',
                                       object: 'document:2021-budget'
                                     },
                                     authorization_model_id: 'KJHGFDSUYTR',
                                     consistency: 'UNSPECIFIED'
                                   },
                                   response_body: { allowed: true, resolution: 'string' })

        response = subject.check(store_id:, user: 'user:anne', relation: :reader, object: 'document:2021-budget',
                                 opts: { authorization_model_id: 'KJHGFDSUYTR' })
        expect(response).to be_a(OpenFga::CheckResponse)
        expect(response.allowed).to be true
      end

      it 'should work with context' do
        stub_request_with_response(method: :post,
                                   path: "#{stores_url(store_id)}/check",
                                   status: 200,
                                   request_body: {
                                     tuple_key: {
                                       user: 'user:anne',
                                       relation: 'reader',
                                       object: 'document:2021-budget'
                                     },
                                     context: {},
                                     consistency: 'UNSPECIFIED'
                                   },
                                   response_body: { allowed: true, resolution: 'string' })

        response = subject.check(store_id:, user: 'user:anne', relation: :reader, object: 'document:2021-budget',
                                 opts: { context: {} })
        expect(response).to be_a(OpenFga::CheckResponse)
        expect(response.allowed).to be true
      end

    end
    # unit tests for expand
    # Expand all relationships in userset tree format, and following userset rewrite rules.  Useful to reason about and debug a certain relationship
    # The Expand API will return all users and usersets that have certain relationship with an object in a certain store. This is different from the &#x60;/stores/{store_id}/read&#x60; API in that both users and computed usersets are returned. Body parameters &#x60;tuple_key.object&#x60; and &#x60;tuple_key.relation&#x60; are all required. A &#x60;contextual_tuples&#x60; object may also be included in the body of the request. This object contains one field &#x60;tuple_keys&#x60;, which is an array of tuple keys. Each of these tuples may have an associated &#x60;condition&#x60;. The response will return a tree whose leaves are the specific users and usersets. Union, intersection and difference operator are located in the intermediate nodes.  ## Example To expand all users that have the &#x60;reader&#x60; relationship with object &#x60;document:2021-budget&#x60;, use the Expand API with the following request body &#x60;&#x60;&#x60;json {   \&quot;tuple_key\&quot;: {     \&quot;object\&quot;: \&quot;document:2021-budget\&quot;,     \&quot;relation\&quot;: \&quot;reader\&quot;   },   \&quot;authorization_model_id\&quot;: \&quot;01G50QVV17PECNVAHX1GG4Y5NC\&quot; } &#x60;&#x60;&#x60; OpenFGA&#39;s response will be a userset tree of the users and usersets that have read access to the document. &#x60;&#x60;&#x60;json {   \&quot;tree\&quot;:{     \&quot;root\&quot;:{       \&quot;type\&quot;:\&quot;document:2021-budget#reader\&quot;,       \&quot;union\&quot;:{         \&quot;nodes\&quot;:[           {             \&quot;type\&quot;:\&quot;document:2021-budget#reader\&quot;,             \&quot;leaf\&quot;:{               \&quot;users\&quot;:{                 \&quot;users\&quot;:[                   \&quot;user:bob\&quot;                 ]               }             }           },           {             \&quot;type\&quot;:\&quot;document:2021-budget#reader\&quot;,             \&quot;leaf\&quot;:{               \&quot;computed\&quot;:{                 \&quot;userset\&quot;:\&quot;document:2021-budget#writer\&quot;               }             }           }         ]       }     }   } } &#x60;&#x60;&#x60; The caller can then call expand API for the &#x60;writer&#x60; relationship for the &#x60;document:2021-budget&#x60;. ### Expand Request with Contextual Tuples  Given the model &#x60;&#x60;&#x60;python model     schema 1.1  type user  type folder     relations         define owner: [user]  type document     relations         define parent: [folder]         define viewer: [user] or writer         define writer: [user] or owner from parent &#x60;&#x60;&#x60; and the initial tuples &#x60;&#x60;&#x60;json [{     \&quot;user\&quot;: \&quot;user:bob\&quot;,     \&quot;relation\&quot;: \&quot;owner\&quot;,     \&quot;object\&quot;: \&quot;folder:1\&quot; }] &#x60;&#x60;&#x60;  To expand all &#x60;writers&#x60; of &#x60;document:1&#x60; when &#x60;document:1&#x60; is put in &#x60;folder:1&#x60;, the first call could be  &#x60;&#x60;&#x60;json {   \&quot;tuple_key\&quot;: {     \&quot;object\&quot;: \&quot;document:1\&quot;,     \&quot;relation\&quot;: \&quot;writer\&quot;   },   \&quot;contextual_tuples\&quot;: {     \&quot;tuple_keys\&quot;: [       {         \&quot;user\&quot;: \&quot;folder:1\&quot;,         \&quot;relation\&quot;: \&quot;parent\&quot;,         \&quot;object\&quot;: \&quot;document:1\&quot;       }     ]   } } &#x60;&#x60;&#x60; this returns: &#x60;&#x60;&#x60;json {   \&quot;tree\&quot;: {     \&quot;root\&quot;: {       \&quot;name\&quot;: \&quot;document:1#writer\&quot;,       \&quot;union\&quot;: {         \&quot;nodes\&quot;: [           {             \&quot;name\&quot;: \&quot;document:1#writer\&quot;,             \&quot;leaf\&quot;: {               \&quot;users\&quot;: {                 \&quot;users\&quot;: []               }             }           },           {             \&quot;name\&quot;: \&quot;document:1#writer\&quot;,             \&quot;leaf\&quot;: {               \&quot;tupleToUserset\&quot;: {                 \&quot;tupleset\&quot;: \&quot;document:1#parent\&quot;,                 \&quot;computed\&quot;: [                   {                     \&quot;userset\&quot;: \&quot;folder:1#owner\&quot;                   }                 ]               }             }           }         ]       }     }   } } &#x60;&#x60;&#x60; This tells us that the &#x60;owner&#x60; of &#x60;folder:1&#x60; may also be a writer. So our next call could be to find the &#x60;owners&#x60; of &#x60;folder:1&#x60; &#x60;&#x60;&#x60;json {   \&quot;tuple_key\&quot;: {     \&quot;object\&quot;: \&quot;folder:1\&quot;,     \&quot;relation\&quot;: \&quot;owner\&quot;   } } &#x60;&#x60;&#x60; which gives &#x60;&#x60;&#x60;json {   \&quot;tree\&quot;: {     \&quot;root\&quot;: {       \&quot;name\&quot;: \&quot;folder:1#owner\&quot;,       \&quot;leaf\&quot;: {         \&quot;users\&quot;: {           \&quot;users\&quot;: [             \&quot;user:bob\&quot;           ]         }       }     }   } } &#x60;&#x60;&#x60;
    # @param store_id
    # @param body
    # @param [Hash] opts the optional parameters
    # @return [ExpandResponse]
    describe 'expand test' do
      it 'should work' do
        # assertion here. ref: https://rspec.info/features/3-12/rspec-expectations/built-in-matchers/
      end
    end

    # unit tests for list_objects
    # List all objects of the given type that the user has a relation with
    # The ListObjects API returns a list of all the objects of the given type that the user has a relation with.  To arrive at a result, the API uses: an authorization model, explicit tuples written through the Write API, contextual tuples present in the request, and implicit tuples that exist by virtue of applying set theory (such as &#x60;document:2021-budget#viewer@document:2021-budget#viewer&#x60;; the set of users who are viewers of &#x60;document:2021-budget&#x60; are the set of users who are the viewers of &#x60;document:2021-budget&#x60;). An &#x60;authorization_model_id&#x60; may be specified in the body. If it is not specified, the latest authorization model ID will be used. It is strongly recommended to specify authorization model id for better performance. You may also specify &#x60;contextual_tuples&#x60; that will be treated as regular tuples. Each of these tuples may have an associated &#x60;condition&#x60;. You may also provide a &#x60;context&#x60; object that will be used to evaluate the conditioned tuples in the system. It is strongly recommended to provide a value for all the input parameters of all the conditions, to ensure that all tuples be evaluated correctly. By default, the Check API caches results for a short time to optimize performance. You may specify a value of &#x60;HIGHER_CONSISTENCY&#x60; for the optional &#x60;consistency&#x60; parameter in the body to inform the server that higher conisistency is preferred at the expense of increased latency. Consideration should be given to the increased latency if requesting higher consistency. The response will contain the related objects in an array in the \&quot;objects\&quot; field of the response and they will be strings in the object format &#x60;&lt;type&gt;:&lt;id&gt;&#x60; (e.g. \&quot;document:roadmap\&quot;). The number of objects in the response array will be limited by the execution timeout specified in the flag OPENFGA_LIST_OBJECTS_DEADLINE and by the upper bound specified in the flag OPENFGA_LIST_OBJECTS_MAX_RESULTS, whichever is hit first. The objects given will not be sorted, and therefore two identical calls can give a given different set of objects.
    # @param store_id
    # @param body
    # @param [Hash] opts the optional parameters
    # @return [ListObjectsResponse]
    describe 'list_objects test' do
      it 'should work' do
        # assertion here. ref: https://rspec.info/features/3-12/rspec-expectations/built-in-matchers/
      end
    end

    # unit tests for list_users
    # List the users matching the provided filter who have a certain relation to a particular type.
    # The ListUsers API returns a list of all the users of a specific type that have a relation to a given object.  To arrive at a result, the API uses: an authorization model, explicit tuples written through the Write API, contextual tuples present in the request, and implicit tuples that exist by virtue of applying set theory (such as &#x60;document:2021-budget#viewer@document:2021-budget#viewer&#x60;; the set of users who are viewers of &#x60;document:2021-budget&#x60; are the set of users who are the viewers of &#x60;document:2021-budget&#x60;). An &#x60;authorization_model_id&#x60; may be specified in the body. If it is not specified, the latest authorization model ID will be used. It is strongly recommended to specify authorization model id for better performance. You may also specify &#x60;contextual_tuples&#x60; that will be treated as regular tuples. Each of these tuples may have an associated &#x60;condition&#x60;. You may also provide a &#x60;context&#x60; object that will be used to evaluate the conditioned tuples in the system. It is strongly recommended to provide a value for all the input parameters of all the conditions, to ensure that all tuples be evaluated correctly. The response will contain the related users in an array in the \&quot;users\&quot; field of the response. These results may include specific objects, usersets  or type-bound public access. Each of these types of results is encoded in its own type and not represented as a string.In cases where a type-bound public access result is returned (e.g. &#x60;user:*&#x60;), it cannot be inferred that all subjects of that type have a relation to the object; it is possible that negations exist and checks should still be queried on individual subjects to ensure access to that document.The number of users in the response array will be limited by the execution timeout specified in the flag OPENFGA_LIST_USERS_DEADLINE and by the upper bound specified in the flag OPENFGA_LIST_USERS_MAX_RESULTS, whichever is hit first. The returned users will not be sorted, and therefore two identical calls may yield different sets of users.
    # @param store_id
    # @param body
    # @param [Hash] opts the optional parameters
    # @return [ListUsersResponse]
    describe 'list_users test' do
      it 'should work' do
        # assertion here. ref: https://rspec.info/features/3-12/rspec-expectations/built-in-matchers/
      end
    end
  end

  describe 'Stores' do
    # unit tests for create_store
    # Create a store
    # Create a unique OpenFGA store which will be used to store authorization models and relationship tuples.
    # @param name [String]
    # @param [Hash] opts the optional parameters
    # @return [CreateStoreResponse]
    context 'when creating a store' do
      let(:store_attributes) { { id: store_id, name: 'new_store', created_at: DateTime.now, updated_at: DateTime.now } }

      it 'creates a store successfully' do
        stub_request_with_response(method: :post,
                                   path: stores_url,
                                   status: 200,
                                   request_body: { name: 'new_store' },
                                   response_body: store_attributes)

        response = subject.create_store('new_store')

        expect(response).to be_instance_of(OpenFga::CreateStoreResponse)
        expect(response.id).to eq(store_id)
      end

      it 'raises an error for invalid store creation request' do
        stub_request_with_response(method: :post,
                                   path: stores_url,
                                   status: 400,
                                   request_body: { name: '' },
                                   response_body: { code: 'validation_error',
                                                    message: 'Generic validation error' })

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
                                   path: stores_url(store_id),
                                   status: 204)
        expect(subject.delete_store(store_id)).to be_nil
      end

      it 'should raise an error id no store_id is set' do
        expect { subject.delete_store(nil) }.to raise_error(ArgumentError)
      end

      it 'should raise an error ' do
        stub_request_with_response(method: :delete,
                                   path: stores_url(store_id),
                                   status: 400,
                                   response_body: { code: 'validation_error',
                                                    message: 'Generic validation error' })
        expect { subject.delete_store(store_id) }.to raise_error(OpenFga::ApiError)
      end
    end

    # unit tests for get_store
    # Get a store
    # Returns an OpenFGA store by its identifier
    # @param store_id
    # @param [Hash] opts the optional parameters
    # @return [GetStoreResponse]
    describe 'when getting a store' do
      let(:store_attributes) { { id: store_id, name: 'new_store', created_at: DateTime.now, updated_at: DateTime.now } }

      it 'should get a store successfully' do
        stub_request_with_response(method: :get,
                                   path: stores_url(store_id),
                                   status: 200,
                                   response_body: store_attributes)
        response = subject.get_store(store_id)
        expect(response).to be_instance_of(OpenFga::GetStoreResponse)
        expect(response.id).to eq(store_id)
      end

      it 'should raise an error id no store_id is set' do
        expect { subject.get_store(nil) }.to raise_error(ArgumentError)
      end

      it 'should raise an error ' do
        stub_request_with_response(method: :get,
                                   path: stores_url(store_id),
                                   status: 400)
        expect { subject.get_store(store_id) }.to raise_error(OpenFga::ApiError)
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
      let(:store_attributes) { { id: store_id, name: 'new_store', created_at: DateTime.now, updated_at: DateTime.now } }

      it 'should list stores successfully' do
        stub_request_with_response(method: :get,
                                   path: stores_url,
                                   status: 200,
                                   response_body: { stores: [store_attributes],
                                                    continuation_token: 'eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ' })
        response = subject.list_stores
        expect(response).to be_instance_of(OpenFga::ListStoresResponse)
        expect(response.stores[0].id).to eq(store_id)
      end

      it 'should raise an error ' do
        stub_request_with_response(method: :get,
                                   path: stores_url,
                                   status: 400)
        expect { subject.list_stores }.to raise_error(OpenFga::ApiError)
      end
    end
  end

  describe 'Tuples' do
    describe 'when reading changes' do
      let(:response_body) { {
        changes: [
          {
            tuple_key: {
              user: 'user:anne',
              relation: 'reader',
              object: 'document:2021-budget',
              condition: {
                name: 'condition1',
                context: {}
              }
            },
            operation: 'TUPLE_OPERATION_WRITE',
            timestamp: '2025-04-23T14:30:00.000Z'
          }
        ],
        continuation_token: 'eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ=='
      } }

      describe 'when there are no options' do
        before do
          stub_request_with_response(method: :get,
                                     path: "#{stores_url(store_id)}/changes",
                                     status: 200,
                                     response_body:)

          @response = subject.read_changes({}, store_id:)
        end

        it 'should read tuple changes successfully' do
          expect(@response).to be_a(OpenFga::ReadChangesResponse)
        end

        it 'contains the expected changes' do
          expect(@response.changes.size).to eq(1)
          expect(@response.changes[0].tuple_key.user).to eq('user:anne')
          expect(@response.changes[0].operation).to eq('TUPLE_OPERATION_WRITE')
        end

        it 'contains a continuation token' do
          expect(@response.continuation_token).not_to be_nil
        end

        it 'should raise an error if store_id is missing' do
          expect { subject.read_changes({}, store_id: nil) }.to raise_error(ArgumentError)
        end

        it 'should not raise an error if the store_id is given as client config' do
          client = OpenFga::SdkClient.new(api_url:, store_id:)
          expect { client.read_changes }.not_to raise_error
        end
      end

      describe 'when there are options' do
        it 'should send the correct request' do
          stub_request_with_response(
            method: :get,
            path: "#{stores_url(store_id)}/changes?page_size=10&type=document&start_time=2025-04-23T14%3A30%3A00.000Z&continuation_token=token",
            status: 200,
            response_body:)

          body = {
            type: :document,
            start_time: '2025-04-23T14:30:00.000Z',
          }

          opts = {
            continuation_token: 'token',
            store_id:,
            page_size: 10
          }

          # call will fail if the request if `path` above is not generated correctly
          # based on `body` and `opts`.
          expect { subject.read_changes(body, opts) }.not_to raise_error
        end
      end
    end
  end
end
