# OpenapiClient::ReadAuthorizationModelsResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **authorization_models** | [**Array&lt;AuthorizationModel&gt;**](AuthorizationModel.md) |  |  |
| **continuation_token** | **String** | The continuation token will be empty if there are no more models. | [optional] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::ReadAuthorizationModelsResponse.new(
  authorization_models: null,
  continuation_token: eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ&#x3D;&#x3D;
)
```

