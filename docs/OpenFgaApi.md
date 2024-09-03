# OpenapiClient::OpenFgaApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**check**](OpenFgaApi.md#check) | **POST** /stores/{store_id}/check | Check whether a user is authorized to access an object |
| [**create_store**](OpenFgaApi.md#create_store) | **POST** /stores | Create a store |
| [**delete_store**](OpenFgaApi.md#delete_store) | **DELETE** /stores/{store_id} | Delete a store |
| [**expand**](OpenFgaApi.md#expand) | **POST** /stores/{store_id}/expand | Expand all relationships in userset tree format, and following userset rewrite rules.  Useful to reason about and debug a certain relationship |
| [**get_store**](OpenFgaApi.md#get_store) | **GET** /stores/{store_id} | Get a store |
| [**list_objects**](OpenFgaApi.md#list_objects) | **POST** /stores/{store_id}/list-objects | List all objects of the given type that the user has a relation with |
| [**list_stores**](OpenFgaApi.md#list_stores) | **GET** /stores | List all stores |
| [**list_users**](OpenFgaApi.md#list_users) | **POST** /stores/{store_id}/list-users | List the users matching the provided filter who have a certain relation to a particular type. |
| [**read**](OpenFgaApi.md#read) | **POST** /stores/{store_id}/read | Get tuples from the store that matches a query, without following userset rewrite rules |
| [**read_assertions**](OpenFgaApi.md#read_assertions) | **GET** /stores/{store_id}/assertions/{authorization_model_id} | Read assertions for an authorization model ID |
| [**read_authorization_model**](OpenFgaApi.md#read_authorization_model) | **GET** /stores/{store_id}/authorization-models/{id} | Return a particular version of an authorization model |
| [**read_authorization_models**](OpenFgaApi.md#read_authorization_models) | **GET** /stores/{store_id}/authorization-models | Return all the authorization models for a particular store |
| [**read_changes**](OpenFgaApi.md#read_changes) | **GET** /stores/{store_id}/changes | Return a list of all the tuple changes |
| [**write**](OpenFgaApi.md#write) | **POST** /stores/{store_id}/write | Add or delete tuples from the store |
| [**write_assertions**](OpenFgaApi.md#write_assertions) | **PUT** /stores/{store_id}/assertions/{authorization_model_id} | Upsert assertions for an authorization model ID |
| [**write_authorization_model**](OpenFgaApi.md#write_authorization_model) | **POST** /stores/{store_id}/authorization-models | Create a new authorization model |


## check

> <CheckResponse> check(store_id, body)

Check whether a user is authorized to access an object

The Check API returns whether a given user has a relationship with a given object in a given store. The `user` field of the request can be a specific target, such as `user:anne`, or a userset (set of users) such as `group:marketing#member` or a type-bound public access `user:*`. To arrive at a result, the API uses: an authorization model, explicit tuples written through the Write API, contextual tuples present in the request, and implicit tuples that exist by virtue of applying set theory (such as `document:2021-budget#viewer@document:2021-budget#viewer`; the set of users who are viewers of `document:2021-budget` are the set of users who are the viewers of `document:2021-budget`). A `contextual_tuples` object may also be included in the body of the request. This object contains one field `tuple_keys`, which is an array of tuple keys. Each of these tuples may have an associated `condition`. You may also provide an `authorization_model_id` in the body. This will be used to assert that the input `tuple_key` is valid for the model specified. If not specified, the assertion will be made against the latest authorization model ID. It is strongly recommended to specify authorization model id for better performance. You may also provide a `context` object that will be used to evaluate the conditioned tuples in the system. It is strongly recommended to provide a value for all the input parameters of all the conditions, to ensure that all tuples be evaluated correctly. The response will return whether the relationship exists in the field `allowed`.  Some exceptions apply, but in general, if a Check API responds with `{allowed: true}`, then you can expect the equivalent ListObjects query to return the object, and viceversa.  For example, if `Check(user:anne, reader, document:2021-budget)` responds with `{allowed: true}`, then `ListObjects(user:anne, reader, document)` may include `document:2021-budget` in the response. ## Examples ### Querying with contextual tuples In order to check if user `user:anne` of type `user` has a `reader` relationship with object `document:2021-budget` given the following contextual tuple ```json {   \"user\": \"user:anne\",   \"relation\": \"member\",   \"object\": \"time_slot:office_hours\" } ``` the Check API can be used with the following request body: ```json {   \"tuple_key\": {     \"user\": \"user:anne\",     \"relation\": \"reader\",     \"object\": \"document:2021-budget\"   },   \"contextual_tuples\": {     \"tuple_keys\": [       {         \"user\": \"user:anne\",         \"relation\": \"member\",         \"object\": \"time_slot:office_hours\"       }     ]   },   \"authorization_model_id\": \"01G50QVV17PECNVAHX1GG4Y5NC\" } ``` ### Querying usersets Some Checks will always return `true`, even without any tuples. For example, for the following authorization model ```python model   schema 1.1 type user type document   relations     define reader: [user] ``` the following query ```json {   \"tuple_key\": {      \"user\": \"document:2021-budget#reader\",      \"relation\": \"reader\",      \"object\": \"document:2021-budget\"   } } ``` will always return `{ \"allowed\": true }`. This is because usersets are self-defining: the userset `document:2021-budget#reader` will always have the `reader` relation with `document:2021-budget`. ### Querying usersets with difference in the model A Check for a userset can yield results that must be treated carefully if the model involves difference. For example, for the following authorization model ```python model   schema 1.1 type user type group   relations     define member: [user] type document   relations     define blocked: [user]     define reader: [group#member] but not blocked ``` the following query ```json {   \"tuple_key\": {      \"user\": \"group:finance#member\",      \"relation\": \"reader\",      \"object\": \"document:2021-budget\"   },   \"contextual_tuples\": {     \"tuple_keys\": [       {         \"user\": \"user:anne\",         \"relation\": \"member\",         \"object\": \"group:finance\"       },       {         \"user\": \"group:finance#member\",         \"relation\": \"reader\",         \"object\": \"document:2021-budget\"       },       {         \"user\": \"user:anne\",         \"relation\": \"blocked\",         \"object\": \"document:2021-budget\"       }     ]   }, } ``` will return `{ \"allowed\": true }`, even though a specific user of the userset `group:finance#member` does not have the `reader` relationship with the given object. 

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 
body = OpenapiClient::CheckRequest.new({tuple_key: OpenapiClient::CheckRequestTupleKey.new({user: 'user:anne', relation: 'reader', object: 'document:2021-budget'})}) # CheckRequest | 

begin
  # Check whether a user is authorized to access an object
  result = api_instance.check(store_id, body)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->check: #{e}"
end
```

#### Using the check_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<CheckResponse>, Integer, Hash)> check_with_http_info(store_id, body)

```ruby
begin
  # Check whether a user is authorized to access an object
  data, status_code, headers = api_instance.check_with_http_info(store_id, body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <CheckResponse>
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->check_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |
| **body** | [**CheckRequest**](CheckRequest.md) |  |  |

### Return type

[**CheckResponse**](CheckResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## create_store

> <CreateStoreResponse> create_store(body)

Create a store

Create a unique OpenFGA store which will be used to store authorization models and relationship tuples.

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
body = OpenapiClient::CreateStoreRequest.new({name: 'my-store-name'}) # CreateStoreRequest | 

begin
  # Create a store
  result = api_instance.create_store(body)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->create_store: #{e}"
end
```

#### Using the create_store_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<CreateStoreResponse>, Integer, Hash)> create_store_with_http_info(body)

```ruby
begin
  # Create a store
  data, status_code, headers = api_instance.create_store_with_http_info(body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <CreateStoreResponse>
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->create_store_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **body** | [**CreateStoreRequest**](CreateStoreRequest.md) |  |  |

### Return type

[**CreateStoreResponse**](CreateStoreResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## delete_store

> delete_store(store_id)

Delete a store

Delete an OpenFGA store. This does not delete the data associated with the store, like tuples or authorization models.

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 

begin
  # Delete a store
  api_instance.delete_store(store_id)
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->delete_store: #{e}"
end
```

#### Using the delete_store_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_store_with_http_info(store_id)

```ruby
begin
  # Delete a store
  data, status_code, headers = api_instance.delete_store_with_http_info(store_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->delete_store_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## expand

> <ExpandResponse> expand(store_id, body)

Expand all relationships in userset tree format, and following userset rewrite rules.  Useful to reason about and debug a certain relationship

The Expand API will return all users and usersets that have certain relationship with an object in a certain store. This is different from the `/stores/{store_id}/read` API in that both users and computed usersets are returned. Body parameters `tuple_key.object` and `tuple_key.relation` are all required. The response will return a tree whose leaves are the specific users and usersets. Union, intersection and difference operator are located in the intermediate nodes.  ## Example To expand all users that have the `reader` relationship with object `document:2021-budget`, use the Expand API with the following request body ```json {   \"tuple_key\": {     \"object\": \"document:2021-budget\",     \"relation\": \"reader\"   },   \"authorization_model_id\": \"01G50QVV17PECNVAHX1GG4Y5NC\" } ``` OpenFGA's response will be a userset tree of the users and usersets that have read access to the document. ```json {   \"tree\":{     \"root\":{       \"type\":\"document:2021-budget#reader\",       \"union\":{         \"nodes\":[           {             \"type\":\"document:2021-budget#reader\",             \"leaf\":{               \"users\":{                 \"users\":[                   \"user:bob\"                 ]               }             }           },           {             \"type\":\"document:2021-budget#reader\",             \"leaf\":{               \"computed\":{                 \"userset\":\"document:2021-budget#writer\"               }             }           }         ]       }     }   } } ``` The caller can then call expand API for the `writer` relationship for the `document:2021-budget`.

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 
body = OpenapiClient::ExpandRequest.new({tuple_key: OpenapiClient::ExpandRequestTupleKey.new({relation: 'reader', object: 'document:2021-budget'})}) # ExpandRequest | 

begin
  # Expand all relationships in userset tree format, and following userset rewrite rules.  Useful to reason about and debug a certain relationship
  result = api_instance.expand(store_id, body)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->expand: #{e}"
end
```

#### Using the expand_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ExpandResponse>, Integer, Hash)> expand_with_http_info(store_id, body)

```ruby
begin
  # Expand all relationships in userset tree format, and following userset rewrite rules.  Useful to reason about and debug a certain relationship
  data, status_code, headers = api_instance.expand_with_http_info(store_id, body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ExpandResponse>
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->expand_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |
| **body** | [**ExpandRequest**](ExpandRequest.md) |  |  |

### Return type

[**ExpandResponse**](ExpandResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## get_store

> <GetStoreResponse> get_store(store_id)

Get a store

Returns an OpenFGA store by its identifier

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 

begin
  # Get a store
  result = api_instance.get_store(store_id)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->get_store: #{e}"
end
```

#### Using the get_store_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GetStoreResponse>, Integer, Hash)> get_store_with_http_info(store_id)

```ruby
begin
  # Get a store
  data, status_code, headers = api_instance.get_store_with_http_info(store_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GetStoreResponse>
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->get_store_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |

### Return type

[**GetStoreResponse**](GetStoreResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## list_objects

> <ListObjectsResponse> list_objects(store_id, body)

List all objects of the given type that the user has a relation with

The ListObjects API returns a list of all the objects of the given type that the user has a relation with.  To arrive at a result, the API uses: an authorization model, explicit tuples written through the Write API, contextual tuples present in the request, and implicit tuples that exist by virtue of applying set theory (such as `document:2021-budget#viewer@document:2021-budget#viewer`; the set of users who are viewers of `document:2021-budget` are the set of users who are the viewers of `document:2021-budget`). An `authorization_model_id` may be specified in the body. If it is not specified, the latest authorization model ID will be used. It is strongly recommended to specify authorization model id for better performance. You may also specify `contextual_tuples` that will be treated as regular tuples. Each of these tuples may have an associated `condition`. You may also provide a `context` object that will be used to evaluate the conditioned tuples in the system. It is strongly recommended to provide a value for all the input parameters of all the conditions, to ensure that all tuples be evaluated correctly. The response will contain the related objects in an array in the \"objects\" field of the response and they will be strings in the object format `<type>:<id>` (e.g. \"document:roadmap\"). The number of objects in the response array will be limited by the execution timeout specified in the flag OPENFGA_LIST_OBJECTS_DEADLINE and by the upper bound specified in the flag OPENFGA_LIST_OBJECTS_MAX_RESULTS, whichever is hit first. The objects given will not be sorted, and therefore two identical calls can give a given different set of objects.

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 
body = OpenapiClient::ListObjectsRequest.new({type: 'document', relation: 'reader', user: 'user:anne'}) # ListObjectsRequest | 

begin
  # List all objects of the given type that the user has a relation with
  result = api_instance.list_objects(store_id, body)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->list_objects: #{e}"
end
```

#### Using the list_objects_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ListObjectsResponse>, Integer, Hash)> list_objects_with_http_info(store_id, body)

```ruby
begin
  # List all objects of the given type that the user has a relation with
  data, status_code, headers = api_instance.list_objects_with_http_info(store_id, body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ListObjectsResponse>
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->list_objects_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |
| **body** | [**ListObjectsRequest**](ListObjectsRequest.md) |  |  |

### Return type

[**ListObjectsResponse**](ListObjectsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## list_stores

> <ListStoresResponse> list_stores(opts)

List all stores

Returns a paginated list of OpenFGA stores and a continuation token to get additional stores. The continuation token will be empty if there are no more stores. 

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
opts = {
  page_size: 56, # Integer | 
  continuation_token: 'continuation_token_example' # String | 
}

begin
  # List all stores
  result = api_instance.list_stores(opts)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->list_stores: #{e}"
end
```

#### Using the list_stores_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ListStoresResponse>, Integer, Hash)> list_stores_with_http_info(opts)

```ruby
begin
  # List all stores
  data, status_code, headers = api_instance.list_stores_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ListStoresResponse>
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->list_stores_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **page_size** | **Integer** |  | [optional] |
| **continuation_token** | **String** |  | [optional] |

### Return type

[**ListStoresResponse**](ListStoresResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## list_users

> <ListUsersResponse> list_users(store_id, body)

List the users matching the provided filter who have a certain relation to a particular type.

The ListUsers API returns a list of all the users of a specific type that have a relation to a given object.  To arrive at a result, the API uses: an authorization model, explicit tuples written through the Write API, contextual tuples present in the request, and implicit tuples that exist by virtue of applying set theory (such as `document:2021-budget#viewer@document:2021-budget#viewer`; the set of users who are viewers of `document:2021-budget` are the set of users who are the viewers of `document:2021-budget`). An `authorization_model_id` may be specified in the body. If it is not specified, the latest authorization model ID will be used. It is strongly recommended to specify authorization model id for better performance. You may also specify `contextual_tuples` that will be treated as regular tuples. Each of these tuples may have an associated `condition`. You may also provide a `context` object that will be used to evaluate the conditioned tuples in the system. It is strongly recommended to provide a value for all the input parameters of all the conditions, to ensure that all tuples be evaluated correctly. The response will contain the related users in an array in the \"users\" field of the response. These results may include specific objects, usersets  or type-bound public access. Each of these types of results is encoded in its own type and not represented as a string.In cases where a type-bound public acces result is returned (e.g. `user:*`), it cannot be inferred that all subjects of that type have a relation to the object; it is possible that negations exist and checks should still be queried on individual subjects to ensure access to that document.The number of users in the response array will be limited by the execution timeout specified in the flag OPENFGA_LIST_USERS_DEADLINE and by the upper bound specified in the flag OPENFGA_LIST_USERS_MAX_RESULTS, whichever is hit first. The returned users will not be sorted, and therefore two identical calls may yield different sets of users.

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 
body = OpenapiClient::ListUsersRequest.new({object: OpenapiClient::FgaObject.new({type: 'document', id: '0bcdf6fa-a6aa-4730-a8eb-9cf172ff16d9'}), relation: 'reader', user_filters: [{type=user},  {type=group,  relation=member}]}) # ListUsersRequest | 

begin
  # List the users matching the provided filter who have a certain relation to a particular type.
  result = api_instance.list_users(store_id, body)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->list_users: #{e}"
end
```

#### Using the list_users_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ListUsersResponse>, Integer, Hash)> list_users_with_http_info(store_id, body)

```ruby
begin
  # List the users matching the provided filter who have a certain relation to a particular type.
  data, status_code, headers = api_instance.list_users_with_http_info(store_id, body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ListUsersResponse>
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->list_users_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |
| **body** | [**ListUsersRequest**](ListUsersRequest.md) |  |  |

### Return type

[**ListUsersResponse**](ListUsersResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## read

> <ReadResponse> read(store_id, body)

Get tuples from the store that matches a query, without following userset rewrite rules

The Read API will return the tuples for a certain store that match a query filter specified in the body of the request.  The API doesn't guarantee order by any field.  It is different from the `/stores/{store_id}/expand` API in that it only returns relationship tuples that are stored in the system and satisfy the query.  In the body: 1. `tuple_key` is optional. If not specified, it will return all tuples in the store. 2. `tuple_key.object` is mandatory if `tuple_key` is specified. It can be a full object (e.g., `type:object_id`) or type only (e.g., `type:`). 3. `tuple_key.user` is mandatory if tuple_key is specified in the case the `tuple_key.object` is a type only. ## Examples ### Query for all objects in a type definition To query for all objects that `user:bob` has `reader` relationship in the `document` type definition, call read API with body of ```json {  \"tuple_key\": {      \"user\": \"user:bob\",      \"relation\": \"reader\",      \"object\": \"document:\"   } } ``` The API will return tuples and a continuation token, something like ```json {   \"tuples\": [     {       \"key\": {         \"user\": \"user:bob\",         \"relation\": \"reader\",         \"object\": \"document:2021-budget\"       },       \"timestamp\": \"2021-10-06T15:32:11.128Z\"     }   ],   \"continuation_token\": \"eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ==\" } ``` This means that `user:bob` has a `reader` relationship with 1 document `document:2021-budget`. Note that this API, unlike the List Objects API, does not evaluate the tuples in the store. The continuation token will be empty if there are no more tuples to query. ### Query for all stored relationship tuples that have a particular relation and object To query for all users that have `reader` relationship with `document:2021-budget`, call read API with body of  ```json {   \"tuple_key\": {      \"object\": \"document:2021-budget\",      \"relation\": \"reader\"    } } ``` The API will return something like  ```json {   \"tuples\": [     {       \"key\": {         \"user\": \"user:bob\",         \"relation\": \"reader\",         \"object\": \"document:2021-budget\"       },       \"timestamp\": \"2021-10-06T15:32:11.128Z\"     }   ],   \"continuation_token\": \"eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ==\" } ``` This means that `document:2021-budget` has 1 `reader` (`user:bob`).  Note that, even if the model said that all `writers` are also `readers`, the API will not return writers such as `user:anne` because it only returns tuples and does not evaluate them. ### Query for all users with all relationships for a particular document To query for all users that have any relationship with `document:2021-budget`, call read API with body of  ```json {   \"tuple_key\": {       \"object\": \"document:2021-budget\"    } } ``` The API will return something like  ```json {   \"tuples\": [     {       \"key\": {         \"user\": \"user:anne\",         \"relation\": \"writer\",         \"object\": \"document:2021-budget\"       },       \"timestamp\": \"2021-10-05T13:42:12.356Z\"     },     {       \"key\": {         \"user\": \"user:bob\",         \"relation\": \"reader\",         \"object\": \"document:2021-budget\"       },       \"timestamp\": \"2021-10-06T15:32:11.128Z\"     }   ],   \"continuation_token\": \"eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ==\" } ``` This means that `document:2021-budget` has 1 `reader` (`user:bob`) and 1 `writer` (`user:anne`). 

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 
body = OpenapiClient::ReadRequest.new # ReadRequest | 

begin
  # Get tuples from the store that matches a query, without following userset rewrite rules
  result = api_instance.read(store_id, body)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->read: #{e}"
end
```

#### Using the read_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ReadResponse>, Integer, Hash)> read_with_http_info(store_id, body)

```ruby
begin
  # Get tuples from the store that matches a query, without following userset rewrite rules
  data, status_code, headers = api_instance.read_with_http_info(store_id, body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ReadResponse>
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->read_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |
| **body** | [**ReadRequest**](ReadRequest.md) |  |  |

### Return type

[**ReadResponse**](ReadResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## read_assertions

> <ReadAssertionsResponse> read_assertions(store_id, authorization_model_id)

Read assertions for an authorization model ID

The ReadAssertions API will return, for a given authorization model id, all the assertions stored for it. An assertion is an object that contains a tuple key, and the expectation of whether a call to the Check API of that tuple key will return true or false. 

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 
authorization_model_id = 'authorization_model_id_example' # String | 

begin
  # Read assertions for an authorization model ID
  result = api_instance.read_assertions(store_id, authorization_model_id)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->read_assertions: #{e}"
end
```

#### Using the read_assertions_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ReadAssertionsResponse>, Integer, Hash)> read_assertions_with_http_info(store_id, authorization_model_id)

```ruby
begin
  # Read assertions for an authorization model ID
  data, status_code, headers = api_instance.read_assertions_with_http_info(store_id, authorization_model_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ReadAssertionsResponse>
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->read_assertions_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |
| **authorization_model_id** | **String** |  |  |

### Return type

[**ReadAssertionsResponse**](ReadAssertionsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## read_authorization_model

> <ReadAuthorizationModelResponse> read_authorization_model(store_id, id)

Return a particular version of an authorization model

The ReadAuthorizationModel API returns an authorization model by its identifier. The response will return the authorization model for the particular version.  ## Example To retrieve the authorization model with ID `01G5JAVJ41T49E9TT3SKVS7X1J` for the store, call the GET authorization-models by ID API with `01G5JAVJ41T49E9TT3SKVS7X1J` as the `id` path parameter.  The API will return: ```json {   \"authorization_model\":{     \"id\":\"01G5JAVJ41T49E9TT3SKVS7X1J\",     \"type_definitions\":[       {         \"type\":\"user\"       },       {         \"type\":\"document\",         \"relations\":{           \"reader\":{             \"union\":{               \"child\":[                 {                   \"this\":{}                 },                 {                   \"computedUserset\":{                     \"object\":\"\",                     \"relation\":\"writer\"                   }                 }               ]             }           },           \"writer\":{             \"this\":{}           }         }       }     ]   } } ``` In the above example, there are 2 types (`user` and `document`). The `document` type has 2 relations (`writer` and `reader`).

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 
id = 'id_example' # String | 

begin
  # Return a particular version of an authorization model
  result = api_instance.read_authorization_model(store_id, id)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->read_authorization_model: #{e}"
end
```

#### Using the read_authorization_model_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ReadAuthorizationModelResponse>, Integer, Hash)> read_authorization_model_with_http_info(store_id, id)

```ruby
begin
  # Return a particular version of an authorization model
  data, status_code, headers = api_instance.read_authorization_model_with_http_info(store_id, id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ReadAuthorizationModelResponse>
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->read_authorization_model_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |
| **id** | **String** |  |  |

### Return type

[**ReadAuthorizationModelResponse**](ReadAuthorizationModelResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## read_authorization_models

> <ReadAuthorizationModelsResponse> read_authorization_models(store_id, opts)

Return all the authorization models for a particular store

The ReadAuthorizationModels API will return all the authorization models for a certain store. OpenFGA's response will contain an array of all authorization models, sorted in descending order of creation.  ## Example Assume that a store's authorization model has been configured twice. To get all the authorization models that have been created in this store, call GET authorization-models. The API will return a response that looks like: ```json {   \"authorization_models\": [     {       \"id\": \"01G50QVV17PECNVAHX1GG4Y5NC\",       \"type_definitions\": [...]     },     {       \"id\": \"01G4ZW8F4A07AKQ8RHSVG9RW04\",       \"type_definitions\": [...]     },   ],   \"continuation_token\": \"eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ==\" } ``` If there are no more authorization models available, the `continuation_token` field will be empty ```json {   \"authorization_models\": [     {       \"id\": \"01G50QVV17PECNVAHX1GG4Y5NC\",       \"type_definitions\": [...]     },     {       \"id\": \"01G4ZW8F4A07AKQ8RHSVG9RW04\",       \"type_definitions\": [...]     },   ],   \"continuation_token\": \"\" } ``` 

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 
opts = {
  page_size: 56, # Integer | 
  continuation_token: 'continuation_token_example' # String | 
}

begin
  # Return all the authorization models for a particular store
  result = api_instance.read_authorization_models(store_id, opts)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->read_authorization_models: #{e}"
end
```

#### Using the read_authorization_models_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ReadAuthorizationModelsResponse>, Integer, Hash)> read_authorization_models_with_http_info(store_id, opts)

```ruby
begin
  # Return all the authorization models for a particular store
  data, status_code, headers = api_instance.read_authorization_models_with_http_info(store_id, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ReadAuthorizationModelsResponse>
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->read_authorization_models_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |
| **page_size** | **Integer** |  | [optional] |
| **continuation_token** | **String** |  | [optional] |

### Return type

[**ReadAuthorizationModelsResponse**](ReadAuthorizationModelsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## read_changes

> <ReadChangesResponse> read_changes(store_id, opts)

Return a list of all the tuple changes

The ReadChanges API will return a paginated list of tuple changes (additions and deletions) that occurred in a given store, sorted by ascending time. The response will include a continuation token that is used to get the next set of changes. If there are no changes after the provided continuation token, the same token will be returned in order for it to be used when new changes are recorded. If the store never had any tuples added or removed, this token will be empty. You can use the `type` parameter to only get the list of tuple changes that affect objects of that type. When reading a write tuple change, if it was conditioned, the condition will be returned. When reading a delete tuple change, the condition will NOT be returned regardless of whether it was originally conditioned or not. 

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 
opts = {
  type: 'type_example', # String | 
  page_size: 56, # Integer | 
  continuation_token: 'continuation_token_example' # String | 
}

begin
  # Return a list of all the tuple changes
  result = api_instance.read_changes(store_id, opts)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->read_changes: #{e}"
end
```

#### Using the read_changes_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ReadChangesResponse>, Integer, Hash)> read_changes_with_http_info(store_id, opts)

```ruby
begin
  # Return a list of all the tuple changes
  data, status_code, headers = api_instance.read_changes_with_http_info(store_id, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ReadChangesResponse>
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->read_changes_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |
| **type** | **String** |  | [optional] |
| **page_size** | **Integer** |  | [optional] |
| **continuation_token** | **String** |  | [optional] |

### Return type

[**ReadChangesResponse**](ReadChangesResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## write

> Object write(store_id, body)

Add or delete tuples from the store

The Write API will transactionally update the tuples for a certain store. Tuples and type definitions allow OpenFGA to determine whether a relationship exists between an object and an user. In the body, `writes` adds new tuples and `deletes` removes existing tuples. When deleting a tuple, any `condition` specified with it is ignored. The API is not idempotent: if, later on, you try to add the same tuple key (even if the `condition` is different), or if you try to delete a non-existing tuple, it will throw an error. The API will not allow you to write tuples such as `document:2021-budget#viewer@document:2021-budget#viewer`, because they are implicit. An `authorization_model_id` may be specified in the body. If it is, it will be used to assert that each written tuple (not deleted) is valid for the model specified. If it is not specified, the latest authorization model ID will be used. ## Example ### Adding relationships To add `user:anne` as a `writer` for `document:2021-budget`, call write API with the following  ```json {   \"writes\": {     \"tuple_keys\": [       {         \"user\": \"user:anne\",         \"relation\": \"writer\",         \"object\": \"document:2021-budget\"       }     ]   },   \"authorization_model_id\": \"01G50QVV17PECNVAHX1GG4Y5NC\" } ``` ### Removing relationships To remove `user:bob` as a `reader` for `document:2021-budget`, call write API with the following  ```json {   \"deletes\": {     \"tuple_keys\": [       {         \"user\": \"user:bob\",         \"relation\": \"reader\",         \"object\": \"document:2021-budget\"       }     ]   } } ``` 

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 
body = OpenapiClient::WriteRequest.new # WriteRequest | 

begin
  # Add or delete tuples from the store
  result = api_instance.write(store_id, body)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->write: #{e}"
end
```

#### Using the write_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(Object, Integer, Hash)> write_with_http_info(store_id, body)

```ruby
begin
  # Add or delete tuples from the store
  data, status_code, headers = api_instance.write_with_http_info(store_id, body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => Object
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->write_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |
| **body** | [**WriteRequest**](WriteRequest.md) |  |  |

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## write_assertions

> write_assertions(store_id, authorization_model_id, body)

Upsert assertions for an authorization model ID

The WriteAssertions API will upsert new assertions for an authorization model id, or overwrite the existing ones. An assertion is an object that contains a tuple key, and the expectation of whether a call to the Check API of that tuple key will return true or false. 

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 
authorization_model_id = 'authorization_model_id_example' # String | 
body = OpenapiClient::WriteAssertionsRequest.new({assertions: [OpenapiClient::Assertion.new({tuple_key: OpenapiClient::AssertionTupleKey.new({object: 'document:2021-budget', relation: 'reader', user: 'user:anne'}), expectation: false})]}) # WriteAssertionsRequest | 

begin
  # Upsert assertions for an authorization model ID
  api_instance.write_assertions(store_id, authorization_model_id, body)
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->write_assertions: #{e}"
end
```

#### Using the write_assertions_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> write_assertions_with_http_info(store_id, authorization_model_id, body)

```ruby
begin
  # Upsert assertions for an authorization model ID
  data, status_code, headers = api_instance.write_assertions_with_http_info(store_id, authorization_model_id, body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->write_assertions_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |
| **authorization_model_id** | **String** |  |  |
| **body** | [**WriteAssertionsRequest**](WriteAssertionsRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## write_authorization_model

> <WriteAuthorizationModelResponse> write_authorization_model(store_id, body)

Create a new authorization model

The WriteAuthorizationModel API will add a new authorization model to a store. Each item in the `type_definitions` array is a type definition as specified in the field `type_definition`. The response will return the authorization model's ID in the `id` field.  ## Example To add an authorization model with `user` and `document` type definitions, call POST authorization-models API with the body:  ```json {   \"type_definitions\":[     {       \"type\":\"user\"     },     {       \"type\":\"document\",       \"relations\":{         \"reader\":{           \"union\":{             \"child\":[               {                 \"this\":{}               },               {                 \"computedUserset\":{                   \"object\":\"\",                   \"relation\":\"writer\"                 }               }             ]           }         },         \"writer\":{           \"this\":{}         }       }     }   ] } ``` OpenFGA's response will include the version id for this authorization model, which will look like  ``` {\"authorization_model_id\": \"01G50QVV17PECNVAHX1GG4Y5NC\"} ``` 

### Examples

```ruby
require 'time'
require 'openapi_client'

api_instance = OpenapiClient::OpenFgaApi.new
store_id = 'store_id_example' # String | 
body = OpenapiClient::WriteAuthorizationModelRequest.new({type_definitions: [OpenapiClient::TypeDefinition.new({type: 'document'})], schema_version: 'schema_version_example'}) # WriteAuthorizationModelRequest | 

begin
  # Create a new authorization model
  result = api_instance.write_authorization_model(store_id, body)
  p result
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->write_authorization_model: #{e}"
end
```

#### Using the write_authorization_model_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<WriteAuthorizationModelResponse>, Integer, Hash)> write_authorization_model_with_http_info(store_id, body)

```ruby
begin
  # Create a new authorization model
  data, status_code, headers = api_instance.write_authorization_model_with_http_info(store_id, body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <WriteAuthorizationModelResponse>
rescue OpenapiClient::ApiError => e
  puts "Error when calling OpenFgaApi->write_authorization_model_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **store_id** | **String** |  |  |
| **body** | [**WriteAuthorizationModelRequest**](WriteAuthorizationModelRequest.md) |  |  |

### Return type

[**WriteAuthorizationModelResponse**](WriteAuthorizationModelResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json

