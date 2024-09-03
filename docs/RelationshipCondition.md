# OpenapiClient::RelationshipCondition

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | A reference (by name) of the relationship condition defined in the authorization model. |  |
| **context** | **Object** | Additional context/data to persist along with the condition. The keys must match the parameters defined by the condition, and the value types must match the parameter type definitions. | [optional] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::RelationshipCondition.new(
  name: condition1,
  context: null
)
```

