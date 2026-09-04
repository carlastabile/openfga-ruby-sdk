# OpenTelemetry metrics → Prometheus

This example runs the full observability stack for the OpenFGA Ruby SDK:

```
Ruby app ──OTLP──▶ OpenTelemetry Collector ──/metrics──▶ Prometheus
```

The SDK records metrics into the OpenTelemetry meter provider. The app exports
them over OTLP to a Collector, which exposes a Prometheus scrape endpoint. This
Collector-based path is the most robust way to get OTel metrics into Prometheus
and doesn't depend on an in-process Prometheus exporter gem.

## Prerequisites

- Ruby 3.2+
- Docker + Docker Compose

## Run it

1. Start OpenFGA, the Collector, and Prometheus:

   ```bash
   docker compose up -d
   ```

2. Run the example app to generate traffic (successes and one deliberate failure):

   ```bash
   ruby main.rb
   ```

3. Open Prometheus at <http://localhost:9090> and query, for example:

   - `fga_client_request_count_total` — request counts, broken down by labels
   - `rate(fga_client_request_count_total{http_response_status_code=~"4..|5.."}[1m])` — error rate
   - `fga_client_request_duration_milliseconds_bucket` — latency histogram

   You can also see the raw scrape output directly from the collector:

   ```bash
   curl -s localhost:9464/metrics | grep fga_client
   ```

## Name mangling (important)

Prometheus doesn't allow dots or dashes, so OpenTelemetry names are rewritten.
Query the Prometheus names, not the SDK names:

| SDK (OpenTelemetry) | Prometheus |
| ------------------- | ---------- |
| `fga-client.request.count` | `fga_client_request_count_total` |
| `fga-client.request.duration` (ms) | `fga_client_request_duration_milliseconds_bucket` / `_sum` / `_count` |
| `fga-client.query.duration` | `fga_client_query_duration_milliseconds_*` |
| attribute `fga-client.request.method` | label `fga_client_request_method` |

## Cardinality

`main.rb` disables the `fga-client.user` and `url.full` attributes on the request
metrics, because they are high-cardinality and would create a large number of
Prometheus series. Adjust the `OpenFga::Telemetry::Configuration` block to taste.

## Note on the Ruby metrics SDK

The OpenTelemetry Ruby **metrics** SDK (`opentelemetry-metrics-sdk`) is still
evolving. The gem versions in `main.rb` are installed via `bundler/inline`; if
the metrics API has changed, pin known-good versions there.
