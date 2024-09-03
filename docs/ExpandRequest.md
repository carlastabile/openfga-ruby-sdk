# OpenapiClient::ExpandRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **tuple_key** | [**ExpandRequestTupleKey**](ExpandRequestTupleKey.md) |  |  |
| **authorization_model_id** | **String** |  | [optional] |
| **consistency** | [**ConsistencyPreference**](ConsistencyPreference.md) |  | [optional][default to &#39;UNSPECIFIED&#39;] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::ExpandRequest.new(
  tuple_key: null,
  authorization_model_id: 01G5JAVJ41T49E9TT3SKVS7X1J,
  consistency: null
)
```

