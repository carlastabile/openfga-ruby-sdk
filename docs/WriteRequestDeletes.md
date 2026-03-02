# OpenFga::WriteRequestDeletes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **tuple_keys** | [**Array&lt;TupleKeyWithoutCondition&gt;**](TupleKeyWithoutCondition.md) |  |  |
| **on_missing** | **String** | On &#39;error&#39;, the API returns an error when deleting a tuple that does not exist. On &#39;ignore&#39;, deletes of non-existent tuples are treated as no-ops. | [optional][default to &#39;error&#39;] |

## Example

```ruby
require 'openfga'

instance = OpenFga::WriteRequestDeletes.new(
  tuple_keys: null,
  on_missing: ignore
)
```


