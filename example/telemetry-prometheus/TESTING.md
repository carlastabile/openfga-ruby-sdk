# Testing the telemetry / Prometheus integration locally

Notes for picking this up another day. Covers both the offline unit path and the
full app → Collector → Prometheus stack.

## Environment notes

- Use **Ruby 3.2.2** (`rvm use ruby-3.2.2`). The repo default 3.0.0 won't run this code.
- `bundle` can't resolve the optional `opentelemetry-api` dev-dependency offline,
  so run RSpec directly with `RUBYOPT="-Ilib -Ispec"`.
- Track B needs **Docker Desktop running** and **network access** (image pulls +
  `bundler/inline` gem installs).

## Track A — Verify the code logic (no Docker, no network)

Runs the unit suite, including the error-path specs.

```bash
cd <repo root>
rvm use ruby-3.2.2

# full suite
RUBYOPT="-Ilib -Ispec" rspec

# just telemetry-related examples
RUBYOPT="-Ilib -Ispec" rspec spec/telemetry spec/client/openfga_client_spec.rb -e Telemetry
```

Expected: `532 examples, 0 failures, 1 pending` (the pending one is the
OTel-not-installed skip). The two error-path tests confirm a failed `check`
records metrics with the failing status code and re-raises `ApiError`.

## Track B — Full end-to-end (app → Collector → Prometheus)

1. Start Docker Desktop, then confirm:
   ```bash
   docker info >/dev/null && echo "daemon up"
   ```

2. Bring up the stack (from `example/telemetry-prometheus/`):
   ```bash
   docker compose up -d
   docker compose ps          # all three should be "running"
   ```

3. Run the demo app (successes + one deliberate failure):
   ```bash
   rvm use ruby-3.2.2
   ruby main.rb
   ```
   First run installs the OTel gems via `bundler/inline`. Expect logs: store
   created, `Expected failure recorded in metrics: <code>`, `Metrics flushed.`

4. Verify from the Collector's scrape endpoint (quickest):
   ```bash
   curl -s localhost:9464/metrics | grep fga_client
   ```
   Look for `fga_client_request_count_total`,
   `fga_client_request_duration_milliseconds_*`, and rows with
   `http_response_status_code="200"` **and** a `4xx` row — the `4xx` row is the
   error-path fix working.

5. Verify in Prometheus UI (<http://localhost:9090>), after ~5–10s scrape delay:
   ```promql
   fga_client_request_count_total
   rate(fga_client_request_count_total{http_response_status_code=~"4..|5.."}[1m])
   ```

6. Tear down:
   ```bash
   docker compose down
   ```

## Troubleshooting

- `ruby main.rb` fails on gem install / OTel API — the Ruby metrics SDK is still
  evolving; pin known-good versions in the `gemfile do` block in `main.rb`.
- No metrics at `:9464` — app pushes on `force_flush` at exit; confirm `main.rb`
  ran to completion and the Collector is up (`docker compose logs otel-collector`).
- Data at `:9464` but nothing in Prometheus — scrape target issue; check
  `docker compose logs prometheus` and Status → Targets shows `otel-collector:9464` UP.

## Still open (follow-up work, not yet implemented)

- `execute_api_request` (arbitrary-endpoint escape hatch) has no
  `request_count` / `request_duration` telemetry.
- Large batch checks (`> max_batch_size`) report `status_code: nil` and no
  `query_duration`, and count the whole logical batch as one request rather than
  per sub-request; sub-batch failures are swallowed with `warn` and not counted.
- Cross-SDK parity: `fga-client.request.count` and `fga-client.http.request.duration`
  are Ruby-specific extras not in the canonical OpenFGA telemetry spec.
- Consider adding a `make run-telemetry-example` target to wrap Track B.
- **Real OTel integration test in CI.** `opentelemetry-api`/`opentelemetry-sdk`
  were removed from the gemspec dev deps because they were never regenerated into
  `Gemfile.lock` (broke frozen `bundle install` in CI) and nothing in the suite
  used the real SDK. When adding a genuine in-process integration test (e.g. with
  `InMemoryMetricPullExporter`), re-add `opentelemetry-sdk` to the gemspec/Gemfile,
  run `bundle install` to regenerate `Gemfile.lock`, and commit the lock together
  with the gemspec change. Until then, real-metrics verification lives in
  `main.rb` via `bundler/inline`.
