# OpenFga::BatchCheckResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **result** | [**Hash&lt;String, BatchCheckSingleResult&gt;**](BatchCheckSingleResult.md) | map keys are the correlation_id values from the BatchCheckItems in the request | [optional] |

## Example

```ruby
require 'openfga'

instance = OpenFga::BatchCheckResponse.new(
  result: {&quot;1cd93d8c-8e45-43c6-9a15-cbb3c7f394bc&quot;:{&quot;allowed&quot;:true,&quot;error&quot;:{&quot;message&quot;:&quot;&quot;}}}
)
```


