# OpenFga::TupleKey

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **user** | **String** |  |  |
| **relation** | **String** |  |  |
| **object** | **String** |  |  |
| **condition** | [**RelationshipCondition**](RelationshipCondition.md) |  | [optional] |

## Example

```ruby
require 'openfga'

instance = OpenFga::TupleKey.new(
  user: user:anne,
  relation: reader,
  object: document:2021-budget,
  condition: null
)
```

