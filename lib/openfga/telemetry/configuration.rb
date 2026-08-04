# frozen_string_literal: true

module OpenFga
  module Telemetry
    class MetricConfiguration
      ATTRIBUTE_DEFAULTS = {
        fga_client_request_client_id:        true,
        fga_client_request_method:           true,
        fga_client_request_model_id:         true,
        fga_client_request_store_id:         true,
        fga_client_request_batch_check_size: false,
        fga_client_response_model_id:        true,
        fga_client_user:                     true,
        http_host:                           true,
        http_request_method:                 true,
        http_request_resend_count:           true,
        http_response_status_code:           true,
        url_scheme:                          true,
        url_full:                            true,
        user_agent_original:                 true
      }.freeze

      attr_accessor :enabled
      ATTRIBUTE_DEFAULTS.each_key { |k| attr_accessor k }

      def initialize(enabled: true)
        @enabled = enabled
        ATTRIBUTE_DEFAULTS.each { |k, v| public_send(:"#{k}=", v) }
      end

      def enabled?
        @enabled
      end

      def attribute_enabled?(attr_key)
        public_send(attr_key) != false
      rescue NoMethodError
        true
      end
    end

    class Configuration
      attr_reader :credentials_request, :request_count, :request_duration,
                  :query_duration, :http_request_duration

      def initialize
        @credentials_request   = MetricConfiguration.new
        @request_count         = MetricConfiguration.new
        @request_duration      = MetricConfiguration.new
        @query_duration        = MetricConfiguration.new
        @http_request_duration = MetricConfiguration.new(enabled: false)
        yield self if block_given?
      end
    end
  end
end
