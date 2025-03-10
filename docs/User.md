# OpenFga::User

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **object** | [**FgaObject**](FgaObject.md) |  | [optional] |
| **userset** | [**UsersetUser**](UsersetUser.md) |  | [optional] |
| **wildcard** | [**TypedWildcard**](TypedWildcard.md) |  | [optional] |

## Example

```ruby
require 'openfga'

instance = OpenFga::User.new(
  object: null,
  userset: null,
  wildcard: null
)
```

