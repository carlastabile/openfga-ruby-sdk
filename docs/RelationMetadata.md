# OpenapiClient::RelationMetadata

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **directly_related_user_types** | [**Array&lt;RelationReference&gt;**](RelationReference.md) |  | [optional] |
| **_module** | **String** |  | [optional] |
| **source_info** | [**SourceInfo**](SourceInfo.md) |  | [optional] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::RelationMetadata.new(
  directly_related_user_types: null,
  _module: null,
  source_info: null
)
```

