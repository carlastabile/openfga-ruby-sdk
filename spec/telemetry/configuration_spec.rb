require 'spec_helper'

describe OpenFga::Telemetry::Configuration do
  subject(:config) { described_class.new }

  describe 'defaults' do
    it 'enables credentials_request metric' do
      expect(config.credentials_request.enabled?).to be true
    end

    it 'enables request_count metric' do
      expect(config.request_count.enabled?).to be true
    end

    it 'enables request_duration metric' do
      expect(config.request_duration.enabled?).to be true
    end

    it 'enables query_duration metric' do
      expect(config.query_duration.enabled?).to be true
    end

    it 'disables http_request_duration metric by default' do
      expect(config.http_request_duration.enabled?).to be false
    end
  end

  describe 'block configuration' do
    subject(:config) do
      described_class.new do |c|
        c.http_request_duration.enabled = true
        c.request_duration.fga_client_request_batch_check_size = true
      end
    end

    it 'applies block overrides' do
      expect(config.http_request_duration.enabled?).to be true
    end

    it 'overrides attribute defaults' do
      expect(config.request_duration.fga_client_request_batch_check_size).to be true
    end
  end
end

describe OpenFga::Telemetry::MetricConfiguration do
  subject(:metric_config) { described_class.new }

  describe 'defaults' do
    it 'is enabled' do
      expect(metric_config.enabled?).to be true
    end

    it 'enables most attributes' do
      expect(metric_config.fga_client_request_method).to be true
      expect(metric_config.fga_client_request_store_id).to be true
      expect(metric_config.fga_client_request_model_id).to be true
      expect(metric_config.http_response_status_code).to be true
      expect(metric_config.user_agent_original).to be true
    end

    it 'disables batch_check_size by default' do
      expect(metric_config.fga_client_request_batch_check_size).to be false
    end
  end

  describe '#attribute_enabled?' do
    it 'returns true for enabled attributes' do
      expect(metric_config.attribute_enabled?(:fga_client_request_method)).to be true
    end

    it 'returns false for disabled attributes' do
      expect(metric_config.attribute_enabled?(:fga_client_request_batch_check_size)).to be false
    end

    it 'returns true for unknown attributes (forward compat)' do
      expect(metric_config.attribute_enabled?(:unknown_future_attr)).to be true
    end
  end

  describe 'disabled metric' do
    subject(:metric_config) { described_class.new(enabled: false) }

    it 'is not enabled' do
      expect(metric_config.enabled?).to be false
    end
  end
end
