require 'spec_helper'

describe OpenFga::Telemetry do
  after { described_class.reset_configuration! }

  describe '.configure' do
    it 'yields the global configuration' do
      described_class.configure do |config|
        config.http_request_duration.enabled = true
      end

      expect(described_class.configuration.http_request_duration.enabled?).to be true
    end
  end

  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(described_class.configuration).to be_a(OpenFga::Telemetry::Configuration)
    end

    it 'returns the same instance on repeated calls' do
      expect(described_class.configuration).to be(described_class.configuration)
    end
  end

  describe '.reset_configuration!' do
    it 'resets to a fresh configuration' do
      described_class.configure { |c| c.http_request_duration.enabled = true }
      described_class.reset_configuration!

      expect(described_class.configuration.http_request_duration.enabled?).to be false
    end
  end

  describe '.get' do
    context 'when opentelemetry-api is not available' do
      before do
        # Simulate OpenTelemetry not being loaded by hiding the constant
        @otel_defined = defined?(OpenTelemetry)
        hide_const('OpenTelemetry') if @otel_defined
      end

      it 'returns a NoopMetrics instance' do
        expect(described_class.get).to be_a(OpenFga::Telemetry::NoopMetrics)
      end
    end

    context 'when opentelemetry-api is available' do
      before do
        require 'opentelemetry-api' rescue nil
      end

      it 'returns a Metrics instance when OpenTelemetry is defined', skip: !defined?(OpenTelemetry) do
        expect(described_class.get).to be_a(OpenFga::Telemetry::Metrics)
      end
    end

    it 'caches the metrics instance per configuration object' do
      config = OpenFga::Telemetry::Configuration.new
      expect(described_class.get(config)).to be(described_class.get(config))
    end

    it 'returns a different instance for different configuration objects' do
      config1 = OpenFga::Telemetry::Configuration.new
      config2 = OpenFga::Telemetry::Configuration.new
      # Both are NoopMetrics (or Metrics), but they are distinct objects
      expect(described_class.get(config1)).not_to be(described_class.get(config2))
    end
  end
end
