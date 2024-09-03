# OpenapiClient::TypeDefinition

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **type** | **String** |  |  |
| **relations** | [**Hash&lt;String, Userset&gt;**](Userset.md) |  | [optional] |
| **metadata** | [**Metadata**](Metadata.md) |  | [optional] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::TypeDefinition.new(
  type: document,
  relations: {&quot;reader&quot;:{&quot;union&quot;:{&quot;child&quot;:[{&quot;this&quot;:{}},{&quot;computedUserset&quot;:{&quot;object&quot;:&quot;&quot;,&quot;relation&quot;:&quot;writer&quot;}}]}},&quot;writer&quot;:{&quot;this&quot;:{}}},
  metadata: null
)
```

