# OpenFga::BatchCheckItem

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **tuple_key** | [**CheckRequestTupleKey**](CheckRequestTupleKey.md) |  |  |
| **correlation_id** | **String** | correlation_id must be a string containing only letters, numbers, or hyphens, with length ≤ 36 characters. |  |
| **contextual_tuples** | [**ContextualTupleKeys**](ContextualTupleKeys.md) |  | [optional] |
| **context** | **Object** |  | [optional] |

## Example

```ruby
require 'openfga'

instance = OpenFga::BatchCheckItem.new(
  tuple_key: null,
  correlation_id: 1cd93d8c-8e45-43c6-9a15-cbb3c7f394bc,
  contextual_tuples: null,
  context: null
)
```


