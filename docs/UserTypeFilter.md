# OpenFga::UserTypeFilter

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **type** | **String** |  |  |
| **relation** | **String** |  | [optional] |

## Example

```ruby
require 'openfga'

instance = OpenFga::UserTypeFilter.new(
  type: group,
  relation: member
)
```

