# OpenapiClient::ReadResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **tuples** | [**Array&lt;Tuple&gt;**](Tuple.md) |  |  |
| **continuation_token** | **String** | The continuation token will be empty if there are no more tuples. |  |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::ReadResponse.new(
  tuples: null,
  continuation_token: eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ&#x3D;&#x3D;
)
```

