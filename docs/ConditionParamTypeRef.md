# OpenFga::ConditionParamTypeRef

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **type_name** | [**TypeName**](TypeName.md) |  | [default to &#39;TYPE_NAME_UNSPECIFIED&#39;] |
| **generic_types** | [**Array&lt;ConditionParamTypeRef&gt;**](ConditionParamTypeRef.md) |  | [optional] |

## Example

```ruby
require 'openfga'

instance = OpenFga::ConditionParamTypeRef.new(
  type_name: null,
  generic_types: null
)
```

