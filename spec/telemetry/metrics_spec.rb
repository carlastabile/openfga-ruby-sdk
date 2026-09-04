require 'spec_helper'

describe OpenFga::Telemetry::Metrics do
  let(:meter) { instance_double('OpenTelemetry::Metrics::Meter') }
  let(:counter) { instance_double('OpenTelemetry::Metrics::Counter') }
  let(:histogram) { instance_double('OpenTelemetry::Metrics::Histogram') }
  let(:configuration) { OpenFga::Telemetry::Configuration.new }

  subject(:metrics) { described_class.new(meter, configuration) }

  before do
    allow(meter).to receive(:create_counter).and_return(counter)
    allow(meter).to receive(:create_histogram).and_return(histogram)
    allow(counter).to receive(:add)
    allow(histogram).to receive(:record)
  end

  describe '#request_count' do
    it 'creates and increments the request count counter' do
      expect(meter).to receive(:create_counter).with(
        OpenFga::Telemetry::Counters::REQUEST_COUNT.name,
        description: OpenFga::Telemetry::Counters::REQUEST_COUNT.description
      ).and_return(counter)

      expect(counter).to receive(:add).with(1, attributes: anything)
      metrics.request_count(1, {})
    end

    it 'caches the counter instrument' do
      expect(meter).to receive(:create_counter).once.and_return(counter)
      2.times { metrics.request_count(1, {}) }
    end

    it 'filters attributes based on metric configuration' do
      attrs = {
        OpenFga::Telemetry::Attributes::FGA_CLIENT_REQUEST_METHOD => 'Check',
        OpenFga::Telemetry::Attributes::FGA_CLIENT_REQUEST_BATCH_CHECK_SIZE => '10'
      }

      expect(counter).to receive(:add) do |_value, attributes:|
        # batch_check_size is disabled by default
        expect(attributes).to include('fga-client.request.method' => 'Check')
        expect(attributes).not_to have_key('fga-client.request.batch_check_size')
      end

      metrics.request_count(1, attrs)
    end
  end

  describe '#request_duration' do
    it 'records the request duration histogram' do
      expect(histogram).to receive(:record).with(42.5, attributes: anything)
      metrics.request_duration(42.5, {})
    end
  end

  describe '#query_duration' do
    it 'records the query duration histogram' do
      expect(histogram).to receive(:record).with(12.3, attributes: anything)
      metrics.query_duration(12.3, {})
    end
  end

  describe '#credentials_request' do
    it 'increments the credentials request counter' do
      expect(counter).to receive(:add).with(1, attributes: anything)
      metrics.credentials_request(1, {})
    end
  end

  describe '#http_request_duration' do
    context 'when http_request_duration is disabled (default)' do
      it 'does not record anything' do
        expect(meter).not_to receive(:create_histogram).with(
          OpenFga::Telemetry::Histograms::HTTP_REQUEST_DURATION.name,
          anything
        )
        metrics.http_request_duration(5.0, {})
      end
    end

    context 'when http_request_duration is enabled' do
      let(:configuration) do
        OpenFga::Telemetry::Configuration.new { |c| c.http_request_duration.enabled = true }
      end

      it 'records the HTTP request duration' do
        expect(histogram).to receive(:record).with(5.0, attributes: anything)
        metrics.http_request_duration(5.0, {})
      end
    end
  end

  describe '#credentials_request' do
    context 'when credentials_request is disabled' do
      let(:configuration) do
        OpenFga::Telemetry::Configuration.new { |c| c.credentials_request.enabled = false }
      end

      it 'does not record anything' do
        expect(counter).not_to receive(:add)
        metrics.credentials_request(1, {})
      end
    end
  end
end
