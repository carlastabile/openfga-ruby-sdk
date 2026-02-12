#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'json'
  gem 'openfga', path: File.expand_path('../../', __dir__)
  gem 'logger'
  gem 'ulid'
  gem 'dotenv'
end

require 'dotenv'
require 'ulid'

logger = Logger.new($stdout)
logger.level = Logger::INFO

ENV_FILE = File.expand_path('./.env', __dir__)
if File.file?(ENV_FILE)
  Dotenv.load(ENV_FILE)
  logger.info "Loaded environment from #{ENV_FILE}"

  # Dump all FGA_* environment variables that are currently set.
  fga_env = ENV.select { |k, _| k.start_with?('FGA_') }
  if fga_env.empty?
    logger.warn 'No FGA_* environment variables are set.'
  else
    logger.info 'Loaded FGA_* variables:'
    fga_env.keys.sort.filter { |k| k != 'FGA_CLIENT_SECRET' }.each { |k| logger.info "  #{k}=#{ENV[k].inspect}" }
  end
else
  logger.warn "No .env found at #{ENV_FILE}"
end

# OpenFGA Ruby SDK Example
# This example demonstrates how to use the OpenFGA Ruby SDK to interact with an OpenFGA server.
class OpenFgaClientCredentialsExample
  def initialize(logger)
    @logger = logger

    if ENV.fetch('FGA_CLIENT_ID', nil).nil? || ENV.fetch('FGA_CLIENT_SECRET', nil).nil?
      @logger.error 'Exiting client credentials example (no client ID or secret)'
      return
    end

    begin
      # Initialize the OpenFGA client
      # Replace with your OpenFGA server URL
      @client = OpenFga::SdkClient.new(
        api_url: ENV.fetch('FGA_API_URL'),
        store_id: ENV.fetch('FGA_STORE_ID'),
        authorization_model_id: ENV.fetch('FGA_MODEL_ID'),
        credentials: {
          method: :client_credentials,
          client_id: ENV.fetch('FGA_CLIENT_ID'),
          client_secret: ENV.fetch('FGA_CLIENT_SECRET'),
          api_token_issuer: ENV.fetch('FGA_API_TOKEN_ISSUER'),
          api_audience: ENV.fetch('FGA_API_AUDIENCE')
        },
        logger: @logger
      )
    rescue StandardError => e
      puts " ❌ #{e.message}"
      exit(1)
    end
  end

  def run
    @logger.info 'Starting OpenFGA Ruby SDK Client Credentials Example'

    # Perform a check operation and ensure the API call succeeds
    check_result = @client.check(user: 'user:steve', relation: :admin, object: 'system:default')

    @logger.info check_result.to_hash.inspect
    @logger.info 'OpenFGA Ruby SDK Client Credentials Example completed'
  rescue => e
    @logger.error "Example failed: #{e.message}"
    @logger.error e.backtrace.join("\n")
    raise e
  end
end

# Run the example if this file is executed directly
if __FILE__ == $0
  example = OpenFgaClientCredentialsExample.new(logger)
  example.run
end
