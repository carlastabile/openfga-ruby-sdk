# OpenapiClient::ReadRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **tuple_key** | [**ReadRequestTupleKey**](ReadRequestTupleKey.md) |  | [optional] |
| **page_size** | **Integer** |  | [optional] |
| **continuation_token** | **String** |  | [optional] |
| **consistency** | [**ConsistencyPreference**](ConsistencyPreference.md) |  | [optional][default to &#39;UNSPECIFIED&#39;] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::ReadRequest.new(
  tuple_key: null,
  page_size: 50,
  continuation_token: eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ&#x3D;&#x3D;,
  consistency: null
)
```

