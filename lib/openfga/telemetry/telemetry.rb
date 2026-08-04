# frozen_string_literal: true

module OpenFga
  module Telemetry
    METER_NAME = 'openfga-sdk'.freeze
    RESPONSE_MODEL_ID_HEADER = 'openfga-authorization-model-id'.freeze

    @mutex = Mutex.new
    @instances = {}

    class << self
      def configure
        yield configuration
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def reset_configuration!
        @configuration = Configuration.new
        @mutex.synchronize { @instances.clear }
      end

      # Returns a Metrics (or NoopMetrics) instance for the given configuration.
      # Caches instances per Configuration object. Uses the global configuration
      # if none is provided.
      def get(config = nil)
        config ||= configuration
        @mutex.synchronize do
          @instances[config] ||= build_metrics(config)
        end
      end

      private

        def build_metrics(config)
          if defined?(OpenTelemetry)
            meter = OpenTelemetry.meter_provider.meter(METER_NAME)
            Metrics.new(meter, config)
          else
            NoopMetrics.new
          end
        end
    end
  end
end
