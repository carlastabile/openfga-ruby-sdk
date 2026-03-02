# OpenFga::UsersetUser

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **type** | **String** |  |  |
| **id** | **String** |  |  |
| **relation** | **String** |  |  |

## Example

```ruby
require 'openfga'

instance = OpenFga::UsersetUser.new(
  type: group,
  id: fga,
  relation: member
)
```


