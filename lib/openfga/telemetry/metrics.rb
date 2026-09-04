# frozen_string_literal: true

module OpenFga
  module Telemetry
    class Metrics
      def initialize(meter, configuration)
        @meter = meter
        @configuration = configuration
        @counters = {}
        @histograms = {}
        @counters_mutex = Mutex.new
        @histograms_mutex = Mutex.new
      end

      def credentials_request(value = 1, attrs = {})
        return unless @configuration.credentials_request.enabled?

        counter = get_counter(Counters::CREDENTIALS_REQUEST)
        counter.add(value, attributes: filter_attributes(attrs, @configuration.credentials_request))
      end

      def request_count(value = 1, attrs = {})
        return unless @configuration.request_count.enabled?

        counter = get_counter(Counters::REQUEST_COUNT)
        counter.add(value, attributes: filter_attributes(attrs, @configuration.request_count))
      end

      def request_duration(value, attrs = {})
        return unless @configuration.request_duration.enabled?

        histogram = get_histogram(Histograms::REQUEST_DURATION)
        histogram.record(value, attributes: filter_attributes(attrs, @configuration.request_duration))
      end

      def query_duration(value, attrs = {})
        return unless @configuration.query_duration.enabled?

        histogram = get_histogram(Histograms::QUERY_DURATION)
        histogram.record(value, attributes: filter_attributes(attrs, @configuration.query_duration))
      end

      def http_request_duration(value, attrs = {})
        return unless @configuration.http_request_duration.enabled?

        histogram = get_histogram(Histograms::HTTP_REQUEST_DURATION)
        histogram.record(value, attributes: filter_attributes(attrs, @configuration.http_request_duration))
      end

      private

        def get_counter(counter_def)
          @counters_mutex.synchronize do
            @counters[counter_def.name] ||= @meter.create_counter(
              counter_def.name,
              description: counter_def.description
            )
          end
        end

        def get_histogram(histogram_def)
          @histograms_mutex.synchronize do
            @histograms[histogram_def.name] ||= @meter.create_histogram(
              histogram_def.name,
              description: histogram_def.description,
              unit: histogram_def.unit
            )
          end
        end

        def filter_attributes(raw_attrs, metric_config)
          raw_attrs.each_with_object({}) do |(attr, value), result|
            next if value.nil?
            next unless metric_config.attribute_enabled?(attr.attr_key)

            result[attr.name] = value
          end
        end
    end
  end
end
