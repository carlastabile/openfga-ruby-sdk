# OpenFga::AssertionTupleKey

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **object** | **String** |  |  |
| **relation** | **String** |  |  |
| **user** | **String** |  |  |

## Example

```ruby
require 'openfga'

instance = OpenFga::AssertionTupleKey.new(
  object: document:2021-budget,
  relation: reader,
  user: user:anne
)
```


