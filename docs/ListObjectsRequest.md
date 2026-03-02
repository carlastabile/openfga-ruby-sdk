# OpenFga::ListObjectsRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **type** | **String** |  |  |
| **relation** | **String** |  |  |
| **user** | **String** |  |  |
| **authorization_model_id** | **String** |  | [optional] |
| **contextual_tuples** | [**ContextualTupleKeys**](ContextualTupleKeys.md) |  | [optional] |
| **context** | **Object** | Additional request context that will be used to evaluate any ABAC conditions encountered in the query evaluation. | [optional] |
| **consistency** | [**ConsistencyPreference**](ConsistencyPreference.md) |  | [optional][default to &#39;UNSPECIFIED&#39;] |

## Example

```ruby
require 'openfga'

instance = OpenFga::ListObjectsRequest.new(
  type: document,
  relation: reader,
  user: user:anne,
  authorization_model_id: 01G5JAVJ41T49E9TT3SKVS7X1J,
  contextual_tuples: null,
  context: null,
  consistency: null
)
```


