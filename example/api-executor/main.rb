#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'json'
  gem 'openfga', path: File.expand_path('../../', __dir__)
  gem 'logger'
end

# OpenFGA API Executor Example
#
# Demonstrates how to call arbitrary OpenFGA API endpoints using
# SdkClient#execute_api_request. Auth headers are injected automatically,
# and path parameters are substituted and URL-encoded.
#
# Usage:
#   FGA_API_URL=http://localhost:8080 ruby example/api-executor/main.rb
#
# Optional env vars:
#   FGA_STORE_ID   — run the check and get-store examples
#   FGA_API_TOKEN  — authenticate with a bearer token

logger = Logger.new($stdout)
logger.level = Logger::INFO

api_url   = ENV.fetch('FGA_API_URL', 'http://localhost:8080')
store_id  = ENV.fetch('FGA_STORE_ID', nil)
api_token = ENV.fetch('FGA_API_TOKEN', nil)

credentials = if api_token
  { method: :api_token, api_token: }
else
  { method: :none }
end

client = OpenFga::SdkClient.new(
  api_url:,
  store_id:,
  credentials:,
  logger:
)

# --- Example 1: GET /stores (no path params, with query params) ---
logger.info '=== Example 1: List stores ==='

response = client.execute_api_request(
  method:       :get,
  path:         '/stores',
  query_params: { page_size: 5 }
)
logger.info "Status : #{response.status}"
logger.info "Success: #{response.success?}"
logger.info "Stores : #{response.data[:stores]&.length || 0} found"

# --- Example 2: GET /stores/{store_id} (path param substitution) ---
if store_id
  logger.info '=== Example 2: Get store by ID ==='

  response = client.execute_api_request(
    method:      :get,
    path:        '/stores/{store_id}',
    path_params: { store_id: }
  )
  logger.info "Status    : #{response.status}"
  logger.info "Store name: #{response.data[:name]}"
else
  logger.warn 'Set FGA_STORE_ID to run example 2'
end

# --- Example 3: POST using the block builder, with custom headers ---
if store_id
  logger.info '=== Example 3: Check authorization via block builder ==='

  response = client.execute_api_request(
    method:      :post,
    path:        '/stores/{store_id}/check',
    path_params: { store_id: },
    body:        {
      tuple_key: {
        user:     'user:anne',
        relation: 'reader',
        object:   'document:2021-budget'
      }
    },
    headers: { 'X-Request-ID' => 'api-executor-example-001' }
  )
  logger.info "Status : #{response.status}"
  logger.info "Allowed: #{response.data[:allowed]}"
else
  logger.warn 'Set FGA_STORE_ID to run example 3'
end

# --- Example 4: Error handling ---
logger.info '=== Example 4: Error handling ==='

begin
  client.execute_api_request(method: :get, path: '/stores/nonexistent-store-id')
rescue OpenFga::ApiError => e
  logger.info "Caught ApiError — HTTP #{e.code}"
end
