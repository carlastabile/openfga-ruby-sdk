# OpenFga::BatchCheckRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **checks** | [**Array&lt;BatchCheckItem&gt;**](BatchCheckItem.md) |  |  |
| **authorization_model_id** | **String** |  | [optional] |
| **consistency** | [**ConsistencyPreference**](ConsistencyPreference.md) |  | [optional][default to &#39;UNSPECIFIED&#39;] |

## Example

```ruby
require 'openfga'

instance = OpenFga::BatchCheckRequest.new(
  checks: null,
  authorization_model_id: 01G5JAVJ41T49E9TT3SKVS7X1J,
  consistency: null
)
```


