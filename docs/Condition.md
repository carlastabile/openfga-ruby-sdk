# OpenapiClient::Condition

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** |  |  |
| **expression** | **String** | A Google CEL expression, expressed as a string. |  |
| **parameters** | [**Hash&lt;String, ConditionParamTypeRef&gt;**](ConditionParamTypeRef.md) | A map of parameter names to the parameter&#39;s defined type reference. | [optional] |
| **metadata** | [**ConditionMetadata**](ConditionMetadata.md) |  | [optional] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::Condition.new(
  name: null,
  expression: null,
  parameters: null,
  metadata: null
)
```

