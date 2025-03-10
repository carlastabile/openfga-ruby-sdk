# OpenFga::CheckRequestTupleKey

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **user** | **String** |  |  |
| **relation** | **String** |  |  |
| **object** | **String** |  |  |

## Example

```ruby
require 'openfga'

instance = OpenFga::CheckRequestTupleKey.new(
  user: user:anne,
  relation: reader,
  object: document:2021-budget
)
```

