# OpenapiClient::CheckRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **tuple_key** | [**CheckRequestTupleKey**](CheckRequestTupleKey.md) |  |  |
| **contextual_tuples** | [**ContextualTupleKeys**](ContextualTupleKeys.md) |  | [optional] |
| **authorization_model_id** | **String** |  | [optional] |
| **trace** | **Boolean** | Defaults to false. Making it true has performance implications. | [optional][readonly] |
| **context** | **Object** | Additional request context that will be used to evaluate any ABAC conditions encountered in the query evaluation. | [optional] |
| **consistency** | [**ConsistencyPreference**](ConsistencyPreference.md) |  | [optional][default to &#39;UNSPECIFIED&#39;] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::CheckRequest.new(
  tuple_key: null,
  contextual_tuples: null,
  authorization_model_id: 01G5JAVJ41T49E9TT3SKVS7X1J,
  trace: false,
  context: null,
  consistency: null
)
```

