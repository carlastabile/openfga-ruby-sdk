# OpenapiClient::PathUnknownErrorMessageResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **code** | [**NotFoundErrorCode**](NotFoundErrorCode.md) |  | [optional][default to &#39;no_not_found_error&#39;] |
| **message** | **String** |  | [optional] |

## Example

```ruby
require 'openapi_client'

instance = OpenapiClient::PathUnknownErrorMessageResponse.new(
  code: null,
  message: null
)
```

