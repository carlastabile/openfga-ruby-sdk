# frozen_string_literal: true

module OpenFga
  module Telemetry
    # HttpDurationTracker is prepended onto the ApiClient singleton class when
    # the http_request_duration metric is enabled. It wraps call_api to record
    # per-HTTP-call duration (including individual retry attempts).
    #
    # To enable, set http_request_duration.enabled = true in the telemetry config.
    # This metric is disabled by default.
    #
    # Injected via SdkClient#initialize:
    #   api_client.instance_variable_set(:@telemetry_metrics, metrics)
    #   api_client.singleton_class.prepend(Telemetry::HttpDurationTracker)
    module HttpDurationTracker
      def call_api(http_method, path, opts = {})
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = super
        duration_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000

        if @telemetry_metrics
          _data, status_code, _headers = result
          attrs = build_http_attrs(http_method, path, status_code)
          @telemetry_metrics.http_request_duration(duration_ms, attrs)
        end

        result
      end

      private

        def build_http_attrs(http_method, path, status_code)
          attrs = {
            Attributes::HTTP_REQUEST_METHOD => http_method.to_s.upcase,
            Attributes::USER_AGENT_ORIGINAL => OpenFga::USER_AGENT
          }

          if @config
            attrs[Attributes::HTTP_HOST]  = @config.host
            attrs[Attributes::URL_SCHEME] = @config.scheme
            attrs[Attributes::URL_FULL]   = "#{@config.scheme}://#{@config.host}#{path}"
          end

          attrs[Attributes::HTTP_RESPONSE_STATUS_CODE] = status_code.to_s if status_code

          attrs
        end
    end
  end
end
