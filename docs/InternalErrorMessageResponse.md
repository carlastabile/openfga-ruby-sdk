# OpenapiClient::InternalErrorMessageResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **code** | [**InternalErrorCode**](InternalErrorCode.md) |  | [optional][default to &#39;no_internal_error&#39;] |
| **message** | **String** |  | [optional] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::InternalErrorMessageResponse.new(
  code: null,
  message: null
)
```

