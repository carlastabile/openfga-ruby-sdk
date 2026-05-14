# Example: Streaming Executor

This example demonstrates using `SdkClient#execute_streaming_api_request` to consume OpenFGA streaming endpoints that use chunked transfer encoding. The example is self-contained - it creates a store, writes an authorization model and tuples, runs the streaming queries, then deletes the store on exit.

## 1. Prerequisites

- Ruby 3.x (uses `bundler/inline` - no separate `bundle install` step needed)
- A running OpenFGA server

## 2. Start OpenFGA (Local Dev)

```bash
make start-openfga
```

Or directly with Docker:

```bash
docker run -p 8080:8080 --name openfga openfga/openfga:latest run
```

## 3. Run the Example

From the repo root:

```bash
ruby example/streaming-executor/main.rb
```

Or from this directory:

```bash
ruby main.rb
```

### With an API token

```bash
FGA_API_TOKEN=<your-token> ruby main.rb
```

## 4. Environment Variables

| Variable        | Required | Description                            | Default                 |
|-----------------|----------|----------------------------------------|-------------------------|
| `FGA_API_URL`   | No       | Base URL of the OpenFGA server         | `http://localhost:8080` |
| `FGA_API_TOKEN` | No       | Bearer token for authenticated requests | *(no auth)*            |

## 5. What the Example Covers

| Example | Demonstrates                                                          |
|---------|-----------------------------------------------------------------------|
| 1       | NDJSON auto-parsing via `Accept: application/x-ndjson` header        |
| 2       | Streaming objects for a second user                                   |
| 3       | Raw chunk access without parsing (no `Accept` header)                 |
| 4       | Error handling with `ApiError`                                        |

## 6. NDJSON Auto-parsing

When the caller sets `Accept: application/x-ndjson`, the method automatically parses each newline-delimited JSON object and yields a symbolized Hash to the block. Without that header the raw chunk String is yielded instead.

```ruby
# Parsed Hash per object (Accept: application/x-ndjson)
client.execute_streaming_api_request(
  method:      :post,
  path:        '/stores/{store_id}/streamed-list-objects',
  path_params: { store_id: 'abc123' },
  headers:     { 'Accept' => 'application/x-ndjson' },
  body:        { type: 'repo', relation: 'reader', user: 'user:anne' }
) do |item|
  puts item.dig(:result, :object)  # item is a Hash
end

# Raw String chunk (no Accept header)
client.execute_streaming_api_request(
  method:      :post,
  path:        '/stores/{store_id}/streamed-list-objects',
  path_params: { store_id: 'abc123' },
  body:        { type: 'repo', relation: 'reader', user: 'user:anne' }
) do |chunk|
  puts chunk  # chunk is a raw String
end
```

## 7. API Reference

```ruby
response = client.execute_streaming_api_request(
  method:       :post,                                        # HTTP verb (symbol or string)
  path:         '/stores/{store_id}/streamed-list-objects',   # Path template
  path_params:  { store_id: 'abc123' },                       # Substituted into {placeholders}
  query_params: { consistency: 'HIGHER_CONSISTENCY' },        # Appended to the URL
  body:         { type: 'repo', relation: 'reader', ... },    # JSON-serialized automatically
  headers:      { 'Accept' => 'application/x-ndjson' }        # Triggers NDJSON auto-parsing
) do |chunk_or_object|
  # String when no Accept header, Hash when Accept: application/x-ndjson
end

response.status   # Integer HTTP status code
response.data     # Always nil - results are yielded to the block
response.headers  # Response headers
response.success? # true for 2xx
```

Auth headers (`Authorization: Bearer ...`) are injected automatically from the client's configured credentials.
