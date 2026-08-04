# frozen_string_literal: true

module OpenFga
  module Telemetry
    # NoopMetrics is used when opentelemetry-api is not available.
    # All recording calls are silently ignored.
    class NoopMetrics
      def credentials_request(_value = nil, _attrs = nil); end

      def request_count(_value = nil, _attrs = nil); end

      def request_duration(_value = nil, _attrs = nil); end

      def query_duration(_value = nil, _attrs = nil); end

      def http_request_duration(_value = nil, _attrs = nil); end
    end
  end
end
