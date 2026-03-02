# OpenFga::ReadRequestTupleKey

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **user** | **String** |  | [optional] |
| **relation** | **String** |  | [optional] |
| **object** | **String** |  | [optional] |

## Example

```ruby
require 'openfga'

instance = OpenFga::ReadRequestTupleKey.new(
  user: user:anne,
  relation: reader,
  object: document:2021-budget
)
```


