require 'spec_helper'

describe OpenFga::Telemetry::NoopMetrics do
  subject(:metrics) { described_class.new }

  it 'accepts credentials_request calls and returns nil' do
    expect(metrics.credentials_request(1, {})).to be_nil
  end

  it 'accepts request_count calls and returns nil' do
    expect(metrics.request_count(1, {})).to be_nil
  end

  it 'accepts request_duration calls and returns nil' do
    expect(metrics.request_duration(12.3, {})).to be_nil
  end

  it 'accepts query_duration calls and returns nil' do
    expect(metrics.query_duration(4.5, {})).to be_nil
  end

  it 'accepts http_request_duration calls and returns nil' do
    expect(metrics.http_request_duration(6.7, {})).to be_nil
  end

  it 'accepts calls with no arguments' do
    expect(metrics.request_count).to be_nil
  end
end
