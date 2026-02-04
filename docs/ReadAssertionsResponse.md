# OpenFga::ReadAssertionsResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **authorization_model_id** | **String** |  |  |
| **assertions** | [**Array&lt;Assertion&gt;**](Assertion.md) |  | [optional] |

## Example

```ruby
require 'openfga'

instance = OpenFga::ReadAssertionsResponse.new(
  authorization_model_id: 01G5JAVJ41T49E9TT3SKVS7X1J,
  assertions: null
)
```


