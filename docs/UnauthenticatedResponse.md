# OpenFga::UnauthenticatedResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **code** | [**ErrorCode**](ErrorCode.md) |  | [optional][default to &#39;no_error&#39;] |
| **message** | **String** |  | [optional] |

## Example

```ruby
require 'openfga'

instance = OpenFga::UnauthenticatedResponse.new(
  code: null,
  message: null
)
```

