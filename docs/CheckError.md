# OpenFga::CheckError

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **input_error** | [**ErrorCode**](ErrorCode.md) |  | [optional][default to &#39;no_error&#39;] |
| **internal_error** | [**InternalErrorCode**](InternalErrorCode.md) |  | [optional][default to &#39;no_internal_error&#39;] |
| **message** | **String** |  | [optional] |

## Example

```ruby
require 'openfga'

instance = OpenFga::CheckError.new(
  input_error: null,
  internal_error: null,
  message: null
)
```


