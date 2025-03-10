# OpenFga::Assertion

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **tuple_key** | [**AssertionTupleKey**](AssertionTupleKey.md) |  |  |
| **expectation** | **Boolean** |  |  |
| **contextual_tuples** | [**Array&lt;TupleKey&gt;**](TupleKey.md) |  | [optional] |
| **context** | **Object** | Additional request context that will be used to evaluate any ABAC conditions encountered in the query evaluation. | [optional] |

## Example

```ruby
require 'openfga'

instance = OpenFga::Assertion.new(
  tuple_key: null,
  expectation: null,
  contextual_tuples: null,
  context: {&quot;view_count&quot;:100}
)
```

