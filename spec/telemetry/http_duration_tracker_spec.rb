require 'spec_helper'

describe OpenFga::Telemetry::HttpDurationTracker do
  # A minimal stand-in for the inner ApiClient that HttpDurationTracker is
  # prepended onto. It exposes @config and @telemetry_metrics like the real one.
  let(:api_client_class) do
    Class.new do
      def initialize(config, telemetry_metrics)
        @config = config
        @telemetry_metrics = telemetry_metrics
      end

      def call_api(_http_method, _path, _opts = {})
        [{ 'ok' => true }, 200, { 'content-type' => 'application/json' }]
      end
    end
  end

  let(:config) { instance_double('OpenFga::Configuration', host: 'localhost:8090', scheme: 'http') }
  let(:metrics) { instance_double(OpenFga::Telemetry::Metrics) }

  let(:api_client) do
    client = api_client_class.new(config, metrics)
    client.singleton_class.prepend(described_class)
    client
  end

  before { allow(metrics).to receive(:http_request_duration) }

  it 'records http_request_duration with a numeric duration' do
    expect(metrics).to receive(:http_request_duration).with(a_kind_of(Numeric), anything)

    api_client.call_api(:post, '/stores/1/check')
  end

  it 'returns the original result from call_api' do
    result = api_client.call_api(:post, '/stores/1/check')
    expect(result).to eq([{ 'ok' => true }, 200, { 'content-type' => 'application/json' }])
  end

  it 'includes HTTP method, host, scheme, full url and status code attributes' do
    expect(metrics).to receive(:http_request_duration) do |_duration, attrs|
      expect(attrs[OpenFga::Telemetry::Attributes::HTTP_REQUEST_METHOD]).to eq('POST')
      expect(attrs[OpenFga::Telemetry::Attributes::HTTP_HOST]).to eq('localhost:8090')
      expect(attrs[OpenFga::Telemetry::Attributes::URL_SCHEME]).to eq('http')
      expect(attrs[OpenFga::Telemetry::Attributes::URL_FULL]).to eq('http://localhost:8090/stores/1/check')
      expect(attrs[OpenFga::Telemetry::Attributes::HTTP_RESPONSE_STATUS_CODE]).to eq('200')
      expect(attrs[OpenFga::Telemetry::Attributes::USER_AGENT_ORIGINAL]).to eq(OpenFga::USER_AGENT)
    end

    api_client.call_api(:post, '/stores/1/check')
  end

  it 'does not raise when telemetry metrics are not set' do
    client = api_client_class.new(config, nil)
    client.singleton_class.prepend(described_class)

    expect { client.call_api(:get, '/stores') }.not_to raise_error
  end
end
