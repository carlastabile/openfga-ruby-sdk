# OpenapiClient::RelationReference

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **type** | **String** |  |  |
| **relation** | **String** |  | [optional] |
| **wildcard** | **Object** |  | [optional] |
| **condition** | **String** | The name of a condition that is enforced over the allowed relation. | [optional] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::RelationReference.new(
  type: group,
  relation: member,
  wildcard: null,
  condition: null
)
```

