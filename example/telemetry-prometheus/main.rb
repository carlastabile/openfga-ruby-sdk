#!/usr/bin/env ruby
# frozen_string_literal: true

# OpenFGA Ruby SDK — OpenTelemetry metrics → Prometheus example.
#
# This script configures the OpenTelemetry metrics SDK to push metrics over OTLP
# to an OpenTelemetry Collector, which in turn exposes them for Prometheus to
# scrape. See README.md and docker-compose.yml for the full stack.
#
# NOTE: The OpenTelemetry Ruby *metrics* SDK is still evolving. The gem versions
# below are pinned to keep this example reproducible; bump them as needed.

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'openfga', path: File.expand_path('../../', __dir__)
  gem 'logger'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-metrics-sdk'
  gem 'opentelemetry-exporter-otlp-metrics'
end

require 'opentelemetry/sdk'
require 'opentelemetry-metrics-sdk'
require 'opentelemetry/exporter/otlp_metrics'
require 'openfga'

# 1. Configure the meter provider with a periodic OTLP metrics exporter.
#    The collector listens for OTLP/HTTP on :4318 (see docker-compose.yml).
OpenTelemetry::SDK.configure { |c| c.service_name = 'openfga-ruby-example' }

exporter = OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.new(
  endpoint: ENV.fetch('OTEL_EXPORTER_OTLP_METRICS_ENDPOINT', 'http://localhost:4318/v1/metrics')
)
OpenTelemetry.meter_provider.add_metric_reader(
  OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(exporter: exporter)
)

# 2. (Optional) Trim high-cardinality attributes so Prometheus label cardinality
#    stays sane. fga-client.user and url.full are the usual offenders.
telemetry = OpenFga::Telemetry::Configuration.new do |t|
  %i[request_count request_duration].each do |metric|
    t.public_send(metric).fga_client_user = false
    t.public_send(metric).url_full        = false
  end
end

logger = Logger.new($stdout)
logger.level = Logger::INFO

# 3. Build the client. Telemetry is picked up automatically because
#    OpenTelemetry is already configured at this point.
api_url = ENV.fetch('FGA_API_URL', 'http://localhost:8080')
client = OpenFga::SdkClient.new(api_url: api_url, telemetry: telemetry, logger: logger)

# 4. Create a store + model so we have something to check against.
store = client.create_store(name: 'telemetry-demo')
store_id = store.id
logger.info("Created store #{store_id}")

model = client.write_authorization_model(
  store_id: store_id,
  schema_version: '1.1',
  type_definitions: [
    { type: 'user' },
    { type: 'document', relations: { reader: { this: {} } },
      metadata: { relations: { reader: { directly_related_user_types: [{ type: 'user' }] } } } }
  ]
)
model_id = model.authorization_model_id

client.write(
  store_id: store_id,
  authorization_model_id: model_id,
  writes: [{ user: 'user:anne', relation: 'reader', object: 'document:roadmap' }]
)

# 5. Generate some traffic — successes AND a deliberate failure so you can see
#    the error metrics that the error-path fix now records.
logger.info('Generating traffic (this drives the metrics)...')
20.times do
  client.check(store_id: store_id, authorization_model_id: model_id,
               user: 'user:anne', relation: 'reader', object: 'document:roadmap')
end

begin
  # Invalid object format → the server returns a 4xx, which is now counted.
  client.check(store_id: store_id, authorization_model_id: model_id,
               user: 'user:anne', relation: 'reader', object: 'not-a-valid-object')
rescue OpenFga::ApiError => e
  logger.info("Expected failure recorded in metrics: #{e.code}")
end

# 6. Flush the metrics before exiting so nothing is lost.
OpenTelemetry.meter_provider.force_flush
logger.info('Metrics flushed. Query Prometheus at http://localhost:9090 for `fga_client_request_count_total`.')
