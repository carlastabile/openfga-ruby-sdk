# OpenFga::ForbiddenResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **code** | [**AuthErrorCode**](AuthErrorCode.md) |  | [optional][default to &#39;no_auth_error&#39;] |
| **message** | **String** |  | [optional] |

## Example

```ruby
require 'openfga'

instance = OpenFga::ForbiddenResponse.new(
  code: null,
  message: null
)
```


