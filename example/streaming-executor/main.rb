#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'json'
  gem 'openfga', path: File.expand_path('../../', __dir__)
  gem 'logger'
end

# OpenFGA Streaming API Executor Example
#
# Demonstrates how to consume streaming (chunked transfer encoding) OpenFGA API
# endpoints using SdkClient#execute_streaming_api_request. Each chunk is yielded
# as a raw String — the caller is responsible for setting the correct Accept header
# and for parsing the chunk content.
#
# Usage:
#   FGA_API_URL=http://localhost:8080 ruby example/streaming-executor/main.rb
#
# Requires a running OpenFGA server. Start one with:
#   make start-openfga

logger = Logger.new($stdout)
logger.level = Logger::INFO

api_url   = ENV.fetch('FGA_API_URL', 'http://localhost:8080')
api_token = ENV.fetch('FGA_API_TOKEN', nil)

credentials = if api_token
  { method: :api_token, api_token: }
else
  { method: :none }
end

# Bootstrap client (no store_id yet)
bootstrap_client = OpenFga::SdkClient.new(api_url:, credentials:, logger:)

# --- Setup: create store, write model and tuples ---
logger.info '=== Setup ==='

store_id = bootstrap_client.create_store(name: 'streaming-executor-example').id
logger.info "Created store: #{store_id}"

client = OpenFga::SdkClient.new(api_url:, store_id:, credentials:, logger:)

model_path = File.expand_path('../common/model.json', __dir__)
authorization_model = JSON.parse(File.read(model_path), symbolize_names: true)
auth_model_id = client.write_authorization_model(**authorization_model).authorization_model_id
logger.info "Wrote authorization model: #{auth_model_id}"

# Write tuples using the github-like repo model:
#   anne is owner of organization:acme → inherits member
#   organization:acme owns repo:sdk and repo:docs
#   anne is directly admin on repo:sdk, so she's also reader of both via org membership
client.write(
  writes: {
    tuple_keys: [
      { user: 'user:anne',             relation: 'owner',  object: 'organization:acme' },
      { user: 'organization:acme',     relation: 'owner',  object: 'repo:sdk'          },
      { user: 'organization:acme',     relation: 'owner',  object: 'repo:docs'         },
      { user: 'user:anne',             relation: 'admin',  object: 'repo:sdk'          },
      { user: 'user:bob',              relation: 'member', object: 'organization:acme' },
      { user: 'user:bob',              relation: 'reader', object: 'repo:docs'         }
    ]
  },
  opts: { authorization_model_id: auth_model_id }
)
logger.info 'Wrote tuples'

# --- Example 1: Stream repos that anne can read ---
# Setting Accept: application/x-ndjson triggers automatic NDJSON parsing;
# the block receives a parsed Hash for each object.
logger.info '=== Example 1: streamed-list-objects for user:anne (reader on repo) ==='

objects = []

client.execute_streaming_api_request(
  method:      :post,
  path:        '/stores/{store_id}/streamed-list-objects',
  path_params: { store_id: },
  headers:     { 'Accept' => 'application/x-ndjson' },
  body:        {
    authorization_model_id: auth_model_id,
    type:                   'repo',
    relation:               'reader',
    user:                   'user:anne'
  }
) do |item|
  object = item.dig(:result, :object)
  logger.info "  received: #{object}"
  objects << object if object
end

logger.info "Total objects received for anne: #{objects.length}"

# --- Example 2: Stream repos that bob can read ---
logger.info '=== Example 2: streamed-list-objects for user:bob (reader on repo) ==='

objects = []

client.execute_streaming_api_request(
  method:      :post,
  path:        '/stores/{store_id}/streamed-list-objects',
  path_params: { store_id: },
  headers:     { 'Accept' => 'application/x-ndjson' },
  body:        {
    authorization_model_id: auth_model_id,
    type:                   'repo',
    relation:               'reader',
    user:                   'user:bob'
  }
) do |item|
  object = item.dig(:result, :object)
  logger.info "  received: #{object}"
  objects << object if object
end

logger.info "Total objects received for bob: #{objects.length}"

# --- Example 3: Consume raw chunks without parsing ---
# Without Accept: application/x-ndjson the block receives the raw String chunk.
logger.info '=== Example 3: raw chunk access ==='

client.execute_streaming_api_request(
  method:      :post,
  path:        '/stores/{store_id}/streamed-list-objects',
  path_params: { store_id: },
  body:        {
    authorization_model_id: auth_model_id,
    type:                   'repo',
    relation:               'admin',
    user:                   'user:anne'
  }
) do |chunk|
  logger.info "  raw chunk (#{chunk.bytesize} bytes): #{chunk.inspect}"
end

# --- Example 4: Error handling ---
logger.info '=== Example 4: error handling ==='

begin
  client.execute_streaming_api_request(
    method:      :post,
    path:        '/stores/{store_id}/streamed-list-objects',
    path_params: { store_id: 'nonexistent-store-id' },
    headers:     { 'Accept' => 'application/x-ndjson' },
    body:        { type: 'repo', relation: 'reader', user: 'user:anne' }
  ) { |chunk| logger.info chunk }
rescue OpenFga::ApiError => e
  logger.info "Caught ApiError — HTTP #{e.code}"
end

# --- Teardown ---
logger.info '=== Teardown ==='
client.delete_store
logger.info "Deleted store: #{store_id}"
