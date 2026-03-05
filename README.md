# Community-driven Ruby SDK for OpenFGA

[![Release](https://img.shields.io/github/v/release/openfga/ruby-sdk?sort=semver&color=green)](https://github.com/openfga/ruby-sdk/releases)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenfga%2Fruby-sdk.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenfga%2Fruby-sdk?ref=badge_shield)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/openfga/ruby-sdk/badge)](https://securityscorecards.dev/viewer/?uri=github.com/openfga/ruby-sdk)
[![Join our community](https://img.shields.io/badge/slack-cncf_%23openfga-40abb8.svg?logo=slack)](https://openfga.dev/community)
[![X](https://img.shields.io/twitter/follow/openfga?color=%23179CF0&logo=x&style=flat-square "@openfga on X")](https://x.com/openfga)

This is community-driven Ruby SDK for OpenFGA. It provides a wrapper around the [OpenFGA API definition](https://openfga.dev/api).

## Table of Contents

- [About OpenFGA](#about)
- [Resources](#resources)
- [Installation](#installation)
- [Getting Started](#getting-started)
  - [Initializing the API Client](#initializing-the-api-client)
  - [Custom Headers](#custom-headers)
  - [Get your Store ID](#get-your-store-id)
  - [Calling the API](#calling-the-api)
    - [Stores](#stores)
      - [List All Stores](#list-stores)
      - [Create a Store](#create-store)
      - [Get a Store](#get-store)
      - [Delete a Store](#delete-store)
    - [Authorization Models](#authorization-models)
      - [Read Authorization Models](#read-authorization-models)
      - [Write Authorization Model](#write-authorization-model)
      - [Read a Single Authorization Model](#read-a-single-authorization-model)
      - [Read the Latest Authorization Model](#read-the-latest-authorization-model)
    - [Relationship Tuples](#relationship-tuples)
      - [Read Relationship Tuple Changes (Watch)](#read-relationship-tuple-changes-watch)
      - [Read Relationship Tuples](#read-relationship-tuples)
      - [Write (Create and Delete) Relationship Tuples](#write-create-and-delete-relationship-tuples)
    - [Relationship Queries](#relationship-queries)
      - [Check](#check)
      - [Batch Check](#batch-check)
      - [Client Batch Check](#client-batch-check)
      - [Expand](#expand)
      - [List Objects](#list-objects)
      - [List Relations](#list-relations)
      - [List Users](#list-users)
    - [Assertions](#assertions)
      - [Read Assertions](#read-assertions)
      - [Write Assertions](#write-assertions)
  - [Retries](#retries)
  - [API Endpoints](#api-endpoints)
  - [Models](#models)
- [Contributing](#contributing)
  - [Issues](#issues)
  - [Pull Requests](#pull-requests)
- [License](#license)

## About

[OpenFGA](https://openfga.dev) is an open source Fine-Grained Authorization solution inspired by [Google's Zanzibar paper](https://research.google/pubs/pub48190/). It was created by the FGA team at [Auth0](https://auth0.com) based on [Auth0 Fine-Grained Authorization (FGA)](https://fga.dev), available under [a permissive license (Apache-2)](https://github.com/openfga/rfcs/blob/main/LICENSE) and welcomes community contributions.

OpenFGA is designed to make it easy for application builders to model their permission layer, and to add and integrate fine-grained authorization into their applications. OpenFGA’s design is optimized for reliability and low latency at a high scale.


## Resources

- [OpenFGA Documentation](https://openfga.dev/docs)
- [OpenFGA API Documentation](https://openfga.dev/api/service)
- [X](https://x.com/openfga)
- [OpenFGA Community](https://openfga.dev/community)
- [Zanzibar Academy](https://zanzibar.academy)
- [Google's Zanzibar Paper (2019)](https://research.google/pubs/pub48190/)

## Installation

To install:

```
gem install openfga
```

Alternatively, you can add it to your `Gemfile`:

```
gem 'openfga'
```

Then run `bundle install` to install the gem.

To use in your code, require the gem and create the configuration:

```
require 'openfga'

sdk_config = {
  api_url: 'http://localhost:8080'
}
```



## Getting Started

### Initializing the API Client

[Learn how to initialize your SDK](https://openfga.dev/docs/getting-started/setup-sdk-client)

We strongly recommend you initialize the `SdkClient` only once and then re-use it 
throughout your app, otherwise you will incur the cost of having to re-initialize 
multiple times or at every request, the cost of reduced connection pooling and 
re-use, and would be particularly costly in the client credentials flow,
as that flow will be performed on every request.

#### No Credentials

```ruby
require 'openfga'

def main
  # Initialize the fga_client
  fga_client = OpenFga::SdkClient.new(
    api_url: ENV['FGA_API_URL'],  # required
    store_id: ENV['FGA_STORE_ID'],  # optional, not needed when calling `create_store` or `list_stores`
    authorization_model_id: ENV['FGA_MODEL_ID']  # optional, can be overridden per request
  )
  
  api_response = fga_client.read_authorization_models()
  return api_response
end
```

#### API Token

```ruby
require 'openfga'

def main
  # Initialize the fga_client
  fga_client = OpenFga::SdkClient.new(
    api_url: ENV['FGA_API_URL'],  # required
    store_id: ENV['FGA_STORE_ID'],  # optional, not needed when calling `create_store` or `list_stores`
    authorization_model_id: ENV['FGA_MODEL_ID'],  # optional, can be overridden per request
    credentials: {
      method: :api_token,
      api_token: ENV['FGA_API_TOKEN']
    }
  )
  
  api_response = fga_client.read_authorization_models()
  return api_response
end
```

#### Client Credentials

```ruby
require 'openfga'

def main
  # Initialize the fga_client
  fga_client = OpenFga::SdkClient.new(
    api_url: ENV['FGA_API_URL'],  # required
    store_id: ENV['FGA_STORE_ID'],  # optional, not needed when calling `create_store` or `list_stores`
    authorization_model_id: ENV['FGA_MODEL_ID'],  # optional, can be overridden per request
    credentials: {
      method: :client_credentials,
      api_token_issuer: ENV['FGA_API_TOKEN_ISSUER'],
      api_audience: ENV['FGA_API_AUDIENCE'],
      client_id: ENV['FGA_CLIENT_ID'],
      client_secret: ENV['FGA_CLIENT_SECRET']
    }
  )
  
  api_response = fga_client.read_authorization_models()
  return api_response
end
```

### Custom Headers

#### Per-Request Headers

You can send custom headers on a per-request basis by using the `opts` parameter. Per-request headers will override any default headers with the same name.

```ruby
require 'openfga'

def main
  # Initialize the fga_client
  fga_client = OpenFga::SdkClient.new(
    api_url: ENV['FGA_API_URL'],
    store_id: ENV['FGA_STORE_ID'],
    authorization_model_id: ENV['FGA_MODEL_ID']
  )
  
  # Add custom headers to a specific request
  result = fga_client.check(
    user: "user:anne",
    relation: "viewer",
    object: "document:roadmap",
    opts: {
      header_params: {
        "X-Request-ID": "123e4567-e89b-12d3-a456-426614174000",
        "X-Custom-Header": "custom-value"
      }
    }
  )
  
  return result
end
```



### Get your Store ID

You need your store id to call the OpenFGA API (unless it is to call the [CreateStore](#create-store) or [ListStores](#list-stores) methods).

If your server is configured with [authentication enabled](https://openfga.dev/docs/getting-started/setup-openfga#configuring-authentication), you also need to have your credentials ready.

### Calling the API

# OpenFga Client Methods

#### Stores

##### List Stores

Get a paginated list of stores.

[API Documentation](https://openfga.dev/api/service#/Stores/ListStores)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

options = { page_size: 25, continuation_token: "eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ==" }
response = fga_client.list_stores(options)
# response = ListStoresResponse(...)
# response.stores = [Store(id: "01FQH7V8BEG3GPQW93KTRFR8JB", name: "FGA Demo Store", created_at: "2022-01-01T00:00:00.000Z", updated_at: "2022-01-01T00:00:00.000Z")]
```

##### Create Store

Create and initialize a store.

[API Documentation](https://openfga.dev/api/service#/Stores/CreateStore)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

body = {
  name: "FGA Demo Store"
}
response = fga_client.create_store(body)
# response.id = "01FQH7V8BEG3GPQW93KTRFR8JB"
```

##### Get Store

Get information about the current store.

[API Documentation](https://openfga.dev/api/service#/Stores/GetStore)

> Requires a client initialized with a store_id

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

response = fga_client.get_store()
# response = OpenFga::GetStoreResponse(id: "01FQH7V8BEG3GPQW93KTRFR8JB", name: "FGA Demo Store", created_at: "2022-01-01T00:00:00.000Z", updated_at: "2022-01-01T00:00:00.000Z")
```

##### Delete Store

Delete a store.

[API Documentation](https://openfga.dev/api/service#/Stores/DeleteStore)

> Requires a client initialized with a store_id

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

response = fga_client.delete_store()
# nil 
```

#### Authorization Models

##### Read Authorization Models

Read all authorization models in the store.

[API Documentation](https://openfga.dev/api/service#/Authorization%20Models/ReadAuthorizationModels)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

options = { page_size: 25, continuation_token: "eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ==" }
response = fga_client.read_authorization_models(options)
# response.authorization_models = [OpenFga::AuthorizationModel(id: '01GXSA8YR785C4FYS3C0RTG7B1', schema_version: '1.1', type_definitions: type_definitions[...]), OpenFga::AuthorizationModel(id: '01GXSBM5PVYHCJNRNKXMB4QZTW', schema_version: '1.1', type_definitions: type_definitions[...])]
```

##### Write Authorization Model

Create a new authorization model.

[API Documentation](https://openfga.dev/api/service#/Authorization%20Models/WriteAuthorizationModel)

> Note: To learn how to build your authorization model, check the Docs at https://openfga.dev/docs.

> Learn more about [the OpenFGA configuration language](https://openfga.dev/docs/configuration-language).

> You can use the [OpenFGA Syntax Transformer](https://github.com/openfga/syntax-transformer) to convert between the friendly DSL and the JSON authorization model.

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

type_definitions = [
  {
    type: "user"
  },
  {
    type: "document",
    relations: {
      writer: { this: {} },
      viewer: {
        union: {
          child: [
            { this: {} },
            {
              computed_userset: {
                object: "",
                relation: "writer"
              }
            }
          ]
        }
      }
    },
    metadata: {
      relations: {
        writer: {
          directly_related_user_types: [
            { type: "user" },
            { type: "user", condition: "ViewCountLessThan200" }
          ]
        },
        viewer: {
          directly_related_user_types: [
            { type: "user" }
          ]
        }
      }
    }
  }
]

conditions = {
  ViewCountLessThan200: {
    name: "ViewCountLessThan200",
    expression: "ViewCount < 200",
    parameters: {
      ViewCount: {
        type_name: "TYPE_NAME_INT"
      },
      Type: {
        type_name: "TYPE_NAME_STRING"
      },
      Name: {
        type_name: "TYPE_NAME_STRING"
      }
    }
  }
}

body = {
  schema_version: "1.1",
  type_definitions: type_definitions,
  conditions: conditions
}

response = fga_client.write_authorization_model(body)
# response.authorization_model_id = "01GXSA8YR785C4FYS3C0RTG7B1"
```

##### Read a Single Authorization Model

Read a particular authorization model.

[API Documentation](https://openfga.dev/api/service#/Authorization%20Models/ReadAuthorizationModel)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

options = {
  # You can rely on the model id set in the configuration or override it for this specific request
  authorization_model_id: "01GXSA8YR785C4FYS3C0RTG7B1"
}

response = fga_client.read_authorization_model(options)
# response.authorization_model = OpenFga::AuthorizationModel(id: '01GXSA8YR785C4FYS3C0RTG7B1', schema_version: '1.1', type_definitions: type_definitions[...])
```

#### Relationship Tuples

##### Read Relationship Tuple Changes (Watch)

Reads the list of historical relationship tuple writes and deletes.

[API Documentation](https://openfga.dev/api/service#/Relationship%20Tuples/ReadChanges)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

options = {
  page_size: 25,
  continuation_token: "eyJwayI6IkxBVEVTVF9OU0NPTkZJR19hdXRoMHN0b3JlIiwic2siOiIxem1qbXF3MWZLZExTcUoyN01MdTdqTjh0cWgifQ=="
}

response = fga_client.read_changes(options)
# response.continuation_token = ...
# response.changes = [TupleChange(tuple_key: TupleKey(object: "...", relation: "...", user: "..."), operation: TupleOperation("TUPLE_OPERATION_WRITE"), timestamp: ...)]
```

##### Read Relationship Tuples

Reads the relationship tuples stored in the database. It does not evaluate nor exclude invalid tuples according to the authorization model.

[API Documentation](https://openfga.dev/api/service#/Relationship%20Tuples/Read)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

# Find if a relationship tuple stating that a certain user is a viewer of certain document
body = {
  user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
  relation: "viewer",
  object: "document:0192ab2a-d83f-756d-9397-c5ed9f3cb69a"
}

response = fga_client.read(body)
# response = ReadResponse(tuples: [Tuple(key: TupleKey(user: "...", relation: "...", object: "..."), timestamp: ...)])
```

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

# Find all relationship tuples where a certain user has a relationship as any relation to a certain document
body = {
  user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
  object: "document:0192ab2a-d83f-756d-9397-c5ed9f3cb69a"
}

response = fga_client.read(body)
# response = ReadResponse(tuples: [Tuple(key: TupleKey(user: "...", relation: "...", object: "..."), timestamp: ...)])
```

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

# Find all relationship tuples where a certain user is a viewer of any document
body = {
  user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
  relation: "viewer",
  object: "document:"
}

response = fga_client.read(body)
# response = ReadResponse(tuples: [Tuple(key: TupleKey(user: "...", relation: "...", object: "..."), timestamp: ...)])
```

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

# Find all relationship tuples where any user has a relationship as any relation with a particular document
body = {
  object: "document:0192ab2a-d83f-756d-9397-c5ed9f3cb69a"
}

response = fga_client.read(body)
# response = ReadResponse(tuples: [Tuple(key: TupleKey(user: "...", relation: "...", object: "..."), timestamp: ...)])
```

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

# Read all stored relationship tuples
body = {}

response = fga_client.read(body)
# response = ReadResponse(tuples: [Tuple(key: TupleKey(user: "...", relation: "...", object: "..."), timestamp: ...)])
```

##### Write (Create and Delete) Relationship Tuples

Create and/or delete relationship tuples to update the system state.

[API Documentation](https://openfga.dev/api/service#/Relationship%20Tuples/Write)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

body = {
  writes: {
    tuple_keys: [
      {
        user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
        relation: "viewer",
        object: "doc:0192ab2a-d83f-756d-9397-c5ed9f3cb69a"
      },
      {
        user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
        relation: "viewer",
        object: "doc:0192ab2d-d36e-7cb3-a4a8-5d1d67a300c5"
      }
    ]
  },
  deletes: {
    tuple_keys: [
      {
        user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
        relation: "writer",
        object: "doc:0192ab2a-d83f-756d-9397-c5ed9f3cb69a"
      }
    ]
  },
  opts: {
    # You can rely on the model id set in the configuration or override it for this specific request
    authorization_model_id: "01GXSA8YR785C4FYS3C0RTG7B1"
  }
}

response = fga_client.write(body)
```

#### Relationship Queries

##### Check

Check if a user has a particular relation with an object.

[API Documentation](https://openfga.dev/api/service#/Relationship%20Queries/Check)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

body = {
  user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
  relation: "writer",
  object: "document:0192ab2a-d83f-756d-9397-c5ed9f3cb69a",
  opts: {
    # You can rely on the model id set in the configuration or override it for this specific request
    authorization_model_id: "01GXSA8YR785C4FYS3C0RTG7B1",
    context: {
      ViewCount: 100
    }
  }
}

response = fga_client.check(body)
# response.allowed = true
```

##### Batch Check

Performs multiple relationship checks in a single batch request.

[API Documentation](https://openfga.dev/api/service#/Relationship%20Queries/BatchCheck)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

body = {
  checks: [
    {
      tuple_key: {
        user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
        relation: "viewer",
        object: "document:0192ab2a-d83f-756d-9397-c5ed9f3cb69a"
      },
      correlation_id: "check-1",
      contextual_tuples: {
        tuple_keys: [
          {
            user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
            relation: "editor",
            object: "document:0192ab2a-d83f-756d-9397-c5ed9f3cb69a"
          }
        ]
      },
      context: {
        ViewCount: 100
      }
    },
    {
      tuple_key: {
        user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
        relation: "admin",
        object: "document:0192ab2a-d83f-756d-9397-c5ed9f3cb69a"
      },
      correlation_id: "check-2"
    }
  ],
  opts: {
    authorization_model_id: "01GXSA8YR785C4FYS3C0RTG7B1",
    max_parallel_requests: 10,
    max_batch_size: 50
  }
}

response = fga_client.batch_check(body)
# response.result contains the results mapped by correlation_id
```

#### Expand

Expands the relationships in userset tree format.

[API Documentation](https://openfga.dev/api/service#/Relationship%20Queries/Expand)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

body = {
  relation: "viewer",
  object: "document:0192ab2a-d83f-756d-9397-c5ed9f3cb69a",
  opts: {
    # You can rely on the model id set in the configuration or override it for this specific request
    authorization_model_id: "01GXSA8YR785C4FYS3C0RTG7B1"
  }
}

response = fga_client.expand(body)
# response = ExpandResponse(tree: UsersetTree(root: Node(name: "document:0192ab2a-d83f-756d-9397-c5ed9f3cb69a#viewer", leaf: Leaf(users: Users(users: ["user:81684243-9356-4421-8fbf-a4f8d36aa31b", "user:f52a4f7a-054d-47ff-bb6e-3ac81269988f"])))))
```

#### List Objects

List the objects of a particular type a user has access to.

[API Documentation](https://openfga.dev/api/service#/Relationship%20Queries/ListObjects)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

body = {
  user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
  relation: "viewer",
  type: "document",
  contextual_tuples: {
    tuple_keys: [
      {
        user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
        relation: "writer",
        object: "document:0192ab2d-d36e-7cb3-a4a8-5d1d67a300c5"
      }
    ]
  },
  context: {
    ViewCount: 100
  },
  opts: {
    # You can rely on the model id set in the configuration or override it for this specific request
    authorization_model_id: "01GXSA8YR785C4FYS3C0RTG7B1"
  }
}

response = fga_client.list_objects(body)
# response.objects = ["document:0192ab2a-d83f-756d-9397-c5ed9f3cb69a"]
```

#### List Users

List the users who have a certain relation to a particular type.

[API Documentation](https://openfga.dev/api/service#/Relationship%20Queries/ListUsers)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

body = {
  relation: "can_read",
  object: "document:2021-budget",
  user_filters: [
    { type: "user" },
    { type: "team", relation: "member" }
  ],
  contextual_tuples: [
    {
      user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
      relation: "editor",
      object: "folder:product"
    },
    {
      user: "folder:product",
      relation: "parent",
      object: "document:0192ab2a-d83f-756d-9397-c5ed9f3cb69a"
    }
  ],
  context: {},
  opts: {
    authorization_model_id: "01GXSA8YR785C4FYS3C0RTG7B1"
  }
}

response = fga_client.list_users(body)
# response.users = [{object: {type: "user", id: "81684243-9356-4421-8fbf-a4f8d36aa31b"}}, {userset: {type: "user"}}, ...]
```

#### Assertions

##### Read Assertions

Read assertions for a particular authorization model.

[API Documentation](https://openfga.dev/api/service#/Assertions/Read%20Assertions)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

options = {
  # You can rely on the model id set in the configuration or override it for this specific request
  authorization_model_id: "01GXSA8YR785C4FYS3C0RTG7B1"
}

response = fga_client.read_assertions(options)
```

##### Write Assertions

Update the assertions for a particular authorization model.

[API Documentation](https://openfga.dev/api/service#/Assertions/Write%20Assertions)

```ruby
# Initialize the fga_client
# fga_client = OpenFga::SdkClient.new(configuration)

body = {
  assertions: [
    {
      user: "user:81684243-9356-4421-8fbf-a4f8d36aa31b",
      relation: "viewer",
      object: "document:0192ab2a-d83f-756d-9397-c5ed9f3cb69a",
      expectation: true
    }
  ],
  opts: {
    # You can rely on the model id set in the configuration or override it for this specific request
    authorization_model_id: "01GXSA8YR785C4FYS3C0RTG7B1"
  }
}

response = fga_client.write_assertions(body)
```

### Retries



### API Endpoints

Class | Method | HTTP request | Description
------------ | ------------- | ------------- | -------------
*OpenFgaApi* | [**batch_check**](docs/OpenFgaApi.md#batch_check) | **POST** /stores/{store_id}/batch-check | Send a list of &#x60;check&#x60; operations in a single request
*OpenFgaApi* | [**check**](docs/OpenFgaApi.md#check) | **POST** /stores/{store_id}/check | Check whether a user is authorized to access an object
*OpenFgaApi* | [**create_store**](docs/OpenFgaApi.md#create_store) | **POST** /stores | Create a store
*OpenFgaApi* | [**delete_store**](docs/OpenFgaApi.md#delete_store) | **DELETE** /stores/{store_id} | Delete a store
*OpenFgaApi* | [**expand**](docs/OpenFgaApi.md#expand) | **POST** /stores/{store_id}/expand | Expand all relationships in userset tree format, and following userset rewrite rules.  Useful to reason about and debug a certain relationship
*OpenFgaApi* | [**get_store**](docs/OpenFgaApi.md#get_store) | **GET** /stores/{store_id} | Get a store
*OpenFgaApi* | [**list_objects**](docs/OpenFgaApi.md#list_objects) | **POST** /stores/{store_id}/list-objects | List all objects of the given type that the user has a relation with
*OpenFgaApi* | [**list_stores**](docs/OpenFgaApi.md#list_stores) | **GET** /stores | List all stores
*OpenFgaApi* | [**list_users**](docs/OpenFgaApi.md#list_users) | **POST** /stores/{store_id}/list-users | List the users matching the provided filter who have a certain relation to a particular type.
*OpenFgaApi* | [**read**](docs/OpenFgaApi.md#read) | **POST** /stores/{store_id}/read | Get tuples from the store that matches a query, without following userset rewrite rules
*OpenFgaApi* | [**read_assertions**](docs/OpenFgaApi.md#read_assertions) | **GET** /stores/{store_id}/assertions/{authorization_model_id} | Read assertions for an authorization model ID
*OpenFgaApi* | [**read_authorization_model**](docs/OpenFgaApi.md#read_authorization_model) | **GET** /stores/{store_id}/authorization-models/{id} | Return a particular version of an authorization model
*OpenFgaApi* | [**read_authorization_models**](docs/OpenFgaApi.md#read_authorization_models) | **GET** /stores/{store_id}/authorization-models | Return all the authorization models for a particular store
*OpenFgaApi* | [**read_changes**](docs/OpenFgaApi.md#read_changes) | **GET** /stores/{store_id}/changes | Return a list of all the tuple changes
*OpenFgaApi* | [**write**](docs/OpenFgaApi.md#write) | **POST** /stores/{store_id}/write | Add or delete tuples from the store
*OpenFgaApi* | [**write_assertions**](docs/OpenFgaApi.md#write_assertions) | **PUT** /stores/{store_id}/assertions/{authorization_model_id} | Upsert assertions for an authorization model ID
*OpenFgaApi* | [**write_authorization_model**](docs/OpenFgaApi.md#write_authorization_model) | **POST** /stores/{store_id}/authorization-models | Create a new authorization model


### Models

 - [AbortedMessageResponse](docs/AbortedMessageResponse.md)
 - [Any](docs/Any.md)
 - [Assertion](docs/Assertion.md)
 - [AssertionTupleKey](docs/AssertionTupleKey.md)
 - [AuthErrorCode](docs/AuthErrorCode.md)
 - [AuthorizationModel](docs/AuthorizationModel.md)
 - [BatchCheckItem](docs/BatchCheckItem.md)
 - [BatchCheckRequest](docs/BatchCheckRequest.md)
 - [BatchCheckResponse](docs/BatchCheckResponse.md)
 - [BatchCheckSingleResult](docs/BatchCheckSingleResult.md)
 - [CheckError](docs/CheckError.md)
 - [CheckRequest](docs/CheckRequest.md)
 - [CheckRequestTupleKey](docs/CheckRequestTupleKey.md)
 - [CheckResponse](docs/CheckResponse.md)
 - [Computed](docs/Computed.md)
 - [Condition](docs/Condition.md)
 - [ConditionMetadata](docs/ConditionMetadata.md)
 - [ConditionParamTypeRef](docs/ConditionParamTypeRef.md)
 - [ConsistencyPreference](docs/ConsistencyPreference.md)
 - [ContextualTupleKeys](docs/ContextualTupleKeys.md)
 - [CreateStoreRequest](docs/CreateStoreRequest.md)
 - [CreateStoreResponse](docs/CreateStoreResponse.md)
 - [Difference](docs/Difference.md)
 - [ErrorCode](docs/ErrorCode.md)
 - [ExpandRequest](docs/ExpandRequest.md)
 - [ExpandRequestTupleKey](docs/ExpandRequestTupleKey.md)
 - [ExpandResponse](docs/ExpandResponse.md)
 - [FgaObject](docs/FgaObject.md)
 - [ForbiddenResponse](docs/ForbiddenResponse.md)
 - [GetStoreResponse](docs/GetStoreResponse.md)
 - [InternalErrorCode](docs/InternalErrorCode.md)
 - [InternalErrorMessageResponse](docs/InternalErrorMessageResponse.md)
 - [Leaf](docs/Leaf.md)
 - [ListObjectsRequest](docs/ListObjectsRequest.md)
 - [ListObjectsResponse](docs/ListObjectsResponse.md)
 - [ListStoresResponse](docs/ListStoresResponse.md)
 - [ListUsersRequest](docs/ListUsersRequest.md)
 - [ListUsersResponse](docs/ListUsersResponse.md)
 - [Metadata](docs/Metadata.md)
 - [Node](docs/Node.md)
 - [Nodes](docs/Nodes.md)
 - [NotFoundErrorCode](docs/NotFoundErrorCode.md)
 - [NullValue](docs/NullValue.md)
 - [ObjectRelation](docs/ObjectRelation.md)
 - [PathUnknownErrorMessageResponse](docs/PathUnknownErrorMessageResponse.md)
 - [ReadAssertionsResponse](docs/ReadAssertionsResponse.md)
 - [ReadAuthorizationModelResponse](docs/ReadAuthorizationModelResponse.md)
 - [ReadAuthorizationModelsResponse](docs/ReadAuthorizationModelsResponse.md)
 - [ReadChangesResponse](docs/ReadChangesResponse.md)
 - [ReadRequest](docs/ReadRequest.md)
 - [ReadRequestTupleKey](docs/ReadRequestTupleKey.md)
 - [ReadResponse](docs/ReadResponse.md)
 - [RelationMetadata](docs/RelationMetadata.md)
 - [RelationReference](docs/RelationReference.md)
 - [RelationshipCondition](docs/RelationshipCondition.md)
 - [SourceInfo](docs/SourceInfo.md)
 - [Status](docs/Status.md)
 - [Store](docs/Store.md)
 - [Tuple](docs/Tuple.md)
 - [TupleChange](docs/TupleChange.md)
 - [TupleKey](docs/TupleKey.md)
 - [TupleKeyWithoutCondition](docs/TupleKeyWithoutCondition.md)
 - [TupleOperation](docs/TupleOperation.md)
 - [TupleToUserset](docs/TupleToUserset.md)
 - [TypeDefinition](docs/TypeDefinition.md)
 - [TypeName](docs/TypeName.md)
 - [TypedWildcard](docs/TypedWildcard.md)
 - [UnauthenticatedResponse](docs/UnauthenticatedResponse.md)
 - [UnprocessableContentErrorCode](docs/UnprocessableContentErrorCode.md)
 - [UnprocessableContentMessageResponse](docs/UnprocessableContentMessageResponse.md)
 - [User](docs/User.md)
 - [UserTypeFilter](docs/UserTypeFilter.md)
 - [Users](docs/Users.md)
 - [Userset](docs/Userset.md)
 - [UsersetTree](docs/UsersetTree.md)
 - [UsersetTreeDifference](docs/UsersetTreeDifference.md)
 - [UsersetTreeTupleToUserset](docs/UsersetTreeTupleToUserset.md)
 - [UsersetUser](docs/UsersetUser.md)
 - [Usersets](docs/Usersets.md)
 - [ValidationErrorMessageResponse](docs/ValidationErrorMessageResponse.md)
 - [WriteAssertionsRequest](docs/WriteAssertionsRequest.md)
 - [WriteAuthorizationModelRequest](docs/WriteAuthorizationModelRequest.md)
 - [WriteAuthorizationModelResponse](docs/WriteAuthorizationModelResponse.md)
 - [WriteRequest](docs/WriteRequest.md)
 - [WriteRequestDeletes](docs/WriteRequestDeletes.md)
 - [WriteRequestWrites](docs/WriteRequestWrites.md)




## Contributing

See [CONTRIBUTING](./CONTRIBUTING.md) for details.

## Author

[OpenFGA](https://github.com/openfga)

## License

This project is licensed under the Apache-2.0 license. See the [LICENSE](https://github.com/openfga/ruby-sdk/blob/main/LICENSE) file for more info.


