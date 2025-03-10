# OpenFga::Metadata

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **relations** | [**Hash&lt;String, RelationMetadata&gt;**](RelationMetadata.md) |  | [optional] |
| **_module** | **String** |  | [optional] |
| **source_info** | [**SourceInfo**](SourceInfo.md) |  | [optional] |

## Example

```ruby
require 'openfga'

instance = OpenFga::Metadata.new(
  relations: null,
  _module: null,
  source_info: null
)
```

