# OpenapiClient::ListStoresResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **stores** | [**Array&lt;Store&gt;**](Store.md) |  |  |
| **continuation_token** | **String** | The continuation token will be empty if there are no more stores. |  |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::ListStoresResponse.new(
  stores: null,
  continuation_token: eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ&#x3D;&#x3D;
)
```

