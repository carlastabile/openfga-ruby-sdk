# OpenapiClient::AuthorizationModel

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **schema_version** | **String** |  |  |
| **type_definitions** | [**Array&lt;TypeDefinition&gt;**](TypeDefinition.md) |  |  |
| **conditions** | [**Hash&lt;String, Condition&gt;**](Condition.md) |  | [optional] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::AuthorizationModel.new(
  id: 01G5JAVJ41T49E9TT3SKVS7X1J,
  schema_version: null,
  type_definitions: [{type&#x3D;user}, {type&#x3D;document, relations&#x3D;{reader&#x3D;{union&#x3D;{child&#x3D;[{this&#x3D;{}}, {computedUserset&#x3D;{object&#x3D;, relation&#x3D;writer}}]}}, writer&#x3D;{this&#x3D;{}}}, metadata&#x3D;{relations&#x3D;{reader&#x3D;{directly_related_user_types&#x3D;[{type&#x3D;user}]}, writer&#x3D;{directly_related_user_types&#x3D;[{type&#x3D;user}]}}}}],
  conditions: null
)
```

