# OpenapiClient::Userset

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **this** | **Object** | A DirectUserset is a sentinel message for referencing the direct members specified by an object/relation mapping. | [optional] |
| **computed_userset** | [**ObjectRelation**](ObjectRelation.md) |  | [optional] |
| **tuple_to_userset** | [**TupleToUserset**](TupleToUserset.md) |  | [optional] |
| **union** | [**Usersets**](Usersets.md) |  | [optional] |
| **intersection** | [**Usersets**](Usersets.md) |  | [optional] |
| **difference** | [**Difference**](Difference.md) |  | [optional] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::Userset.new(
  this: null,
  computed_userset: null,
  tuple_to_userset: null,
  union: null,
  intersection: null,
  difference: null
)
```

