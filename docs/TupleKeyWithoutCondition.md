# OpenFga::TupleKeyWithoutCondition

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **user** | **String** |  |  |
| **relation** | **String** |  |  |
| **object** | **String** |  |  |

## Example

```ruby
require 'openfga'

instance = OpenFga::TupleKeyWithoutCondition.new(
  user: user:anne,
  relation: reader,
  object: document:2021-budget
)
```

