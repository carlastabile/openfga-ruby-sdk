# Example: API Executor

This example demonstrates using `SdkClient#execute_api_request` to call arbitrary OpenFGA API endpoints. Rather than using the SDK's typed methods, you supply an HTTP method, path, and optional parameters directly - useful for endpoints not yet covered by the SDK or for advanced use cases.

## 1. Prerequisites

- Ruby 3.x (uses `bundler/inline` - no separate `bundle install` step needed)
- A running OpenFGA server

## 2. Start OpenFGA (Local Dev)

```bash
docker run -p 8080:8080 --name openfga openfga/openfga:latest run
```

Or from the repo root:

```bash
make start-openfga
```

## 3. Run the Example

From the repo root:

```bash
ruby example/api-executor/main.rb
```

Or from this directory:

```bash
ruby main.rb
```

### With a store ID (enables the check example)

```bash
FGA_STORE_ID=<your-store-id> ruby main.rb
```

### With an API token

```bash
FGA_API_TOKEN=<your-token> FGA_STORE_ID=<your-store-id> ruby main.rb
```

## 4. Environment Variables

| Variable        | Required | Description                                       | Default                  |
|-----------------|----------|---------------------------------------------------|--------------------------|
| `FGA_API_URL`   | No       | Base URL of the OpenFGA server                    | `http://localhost:8080`  |
| `FGA_STORE_ID`  | No       | Store ID for path-param and check examples        | *(skips those examples)* |
| `FGA_API_TOKEN` | No       | Bearer token for authenticated requests           | *(no auth)*              |

## 5. What the Example Covers

| Example | Method | Path                           | Demonstrates                        |
|---------|--------|--------------------------------|-------------------------------------|
| 1       | GET    | `/stores`                      | Query params, basic response access |
| 2       | GET    | `/stores/{store_id}`           | Path param substitution             |
| 3       | POST   | `/stores/{store_id}/check`     | Request body, custom headers        |
| 4       | GET    | `/stores/nonexistent-store-id` | Error handling with `ApiError`      |

## 6. API Reference

```ruby
response = client.execute_api_request(
  method:       :post,                        # HTTP verb (symbol or string)
  path:         '/stores/{store_id}/check',   # Path template
  path_params:  { store_id: 'abc123' },       # Substituted into {placeholders}
  query_params: { consistency: 'STRONG' },    # Appended to the URL
  body:         { tuple_key: { ... } },       # JSON-serialized automatically
  headers:      { 'X-Request-ID' => 'xyz' }  # Merged with SDK defaults
)

response.status   # Integer HTTP status code
response.data     # Hash with symbolized keys (parsed JSON body)
response.headers  # Response headers
response.success? # true for 2xx
```

Auth headers (`Authorization: Bearer ...`) are injected automatically from the client's configured credentials.
