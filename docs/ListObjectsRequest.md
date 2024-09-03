# OpenapiClient::ListObjectsRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **authorization_model_id** | **String** |  | [optional] |
| **type** | **String** |  |  |
| **relation** | **String** |  |  |
| **user** | **String** |  |  |
| **contextual_tuples** | [**ContextualTupleKeys**](ContextualTupleKeys.md) |  | [optional] |
| **context** | **Object** | Additional request context that will be used to evaluate any ABAC conditions encountered in the query evaluation. | [optional] |
| **consistency** | [**ConsistencyPreference**](ConsistencyPreference.md) |  | [optional][default to &#39;UNSPECIFIED&#39;] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::ListObjectsRequest.new(
  authorization_model_id: 01G5JAVJ41T49E9TT3SKVS7X1J,
  type: document,
  relation: reader,
  user: user:anne,
  contextual_tuples: null,
  context: null,
  consistency: null
)
```

