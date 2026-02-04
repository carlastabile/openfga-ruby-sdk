# OpenFga::WriteRequestWrites

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **tuple_keys** | [**Array&lt;TupleKey&gt;**](TupleKey.md) |  |  |
| **on_duplicate** | **String** | On &#39;error&#39; ( or unspecified ), the API returns an error if an identical tuple already exists. On &#39;ignore&#39;, identical writes are treated as no-ops (matching on user, relation, object, and RelationshipCondition). | [optional][default to &#39;error&#39;] |

## Example

```ruby
require 'openfga'

instance = OpenFga::WriteRequestWrites.new(
  tuple_keys: null,
  on_duplicate: ignore
)
```


