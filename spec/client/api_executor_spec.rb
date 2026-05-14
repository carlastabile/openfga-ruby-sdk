require 'spec_helper'

describe OpenFga::ApiExecutorRequest do
  describe '.new' do
    it 'accepts keyword arguments' do
      req = described_class.new(
        method: :get,
        path: '/stores',
        query_params: { page_size: 10 }
      )
      expect(req.method).to eq(:get)
      expect(req.path).to eq('/stores')
      expect(req.query_params).to eq({ page_size: 10 })
    end

    it 'defaults path_params, query_params, and headers to empty hashes' do
      req = described_class.new(method: :get, path: '/stores')
      expect(req.path_params).to  eq({})
      expect(req.query_params).to eq({})
      expect(req.headers).to      eq({})
    end

    it 'defaults body to nil' do
      req = described_class.new(method: :get, path: '/stores')
      expect(req.body).to be_nil
    end
  end

  describe '#validate!' do
    it 'raises ArgumentError when method is nil' do
      req = described_class.new(method: nil, path: '/stores')
      expect { req.validate! }.to raise_error(ArgumentError, /method is required/)
    end

    it 'raises ArgumentError when path is empty' do
      req = described_class.new(method: :get, path: '')
      expect { req.validate! }.to raise_error(ArgumentError, /path is required/)
    end

    it 'does not raise when method and path are present' do
      req = described_class.new(method: :get, path: '/stores')
      expect { req.validate! }.not_to raise_error
    end
  end
end

describe OpenFga::ApiExecutorResponse do
  it 'exposes data, status, and headers' do
    resp = described_class.new(data: { allowed: true }, status: 200, headers: { 'x-foo' => 'bar' })
    expect(resp.data).to    eq({ allowed: true })
    expect(resp.status).to  eq(200)
    expect(resp.headers).to eq({ 'x-foo' => 'bar' })
  end

  it '#success? returns true for 2xx' do
    expect(described_class.new(data: nil, status: 200, headers: {}).success?).to be(true)
    expect(described_class.new(data: nil, status: 201, headers: {}).success?).to be(true)
  end

  it '#success? returns false for non-2xx' do
    expect(described_class.new(data: nil, status: 404, headers: {}).success?).to be(false)
    expect(described_class.new(data: nil, status: 500, headers: {}).success?).to be(false)
  end
end

describe OpenFga::SdkClient, '#execute_api_request' do
  let(:api_url)  { 'http://localhost:8090' }
  let(:store_id) { '01JSKYVY76JYW2DG65NG1444T4' }
  let(:subject)  { OpenFga::SdkClient.new(api_url:, store_id:) }

  let(:subject_with_token) do
    OpenFga::SdkClient.new(
      api_url:,
      store_id:,
      credentials: { method: :api_token, api_token: 'my-token' }
    )
  end

  it 'raises ArgumentError when method is missing' do
    expect { subject.execute_api_request(path: '/stores') }
      .to raise_error(ArgumentError)
  end

  it 'raises ArgumentError when path is empty' do
    expect { subject.execute_api_request(method: :get, path: '') }
      .to raise_error(ArgumentError, /path is required/)
  end

  context 'GET without path params' do
    it 'calls the correct URL and returns an ApiExecutorResponse' do
      stub_request(:get, "#{api_url}/stores")
        .to_return(
          status: 200,
          body: { stores: [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      resp = subject.execute_api_request(method: :get, path: '/stores')

      expect(resp).to be_a(OpenFga::ApiExecutorResponse)
      expect(resp.status).to  eq(200)
      expect(resp.data).to    eq({ stores: [] })
      expect(resp.success?).to be(true)
    end
  end

  context 'POST with path param substitution' do
    it 'substitutes {store_id} in the path' do
      stub = stub_request(:post, "#{api_url}/stores/#{store_id}/check")
        .to_return(
          status: 200,
          body: { allowed: true }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      resp = subject.execute_api_request(
        method:      :post,
        path:        '/stores/{store_id}/check',
        path_params: { store_id: store_id },
        body:        { tuple_key: { user: 'user:anne', relation: 'reader', object: 'doc:1' } }
      )

      expect(stub).to have_been_requested
      expect(resp.data[:allowed]).to be(true)
    end

    it 'accepts symbol keys in path_params' do
      stub = stub_request(:get, "#{api_url}/stores/#{store_id}")
        .to_return(
          status: 200,
          body: { id: store_id }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      subject.execute_api_request(
        method:      :get,
        path:        '/stores/{store_id}',
        path_params: { store_id: store_id }
      )

      expect(stub).to have_been_requested
    end

    it 'raises an error when a placeholder has no matching path_param' do
      expect {
        subject.execute_api_request(method: :get, path: '/stores/{unknown_key}')
      }.to raise_error(URI::InvalidURIError)
    end
  end

  context 'auth header injection' do
    it 'injects Authorization header when api_token credential is configured' do
      stub = stub_request(:get, "#{api_url}/stores")
        .with(headers: { 'Authorization' => 'Bearer my-token' })
        .to_return(
          status: 200,
          body: { stores: [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      subject_with_token.execute_api_request(method: :get, path: '/stores')

      expect(stub).to have_been_requested
    end

    it 'caller-supplied headers are merged and override SDK auth headers' do
      stub = stub_request(:get, "#{api_url}/stores")
        .with(headers: { 'Authorization' => 'Bearer caller-override', 'X-Custom' => 'value' })
        .to_return(
          status: 200,
          body: {}.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      subject_with_token.execute_api_request(
        method:  :get,
        path:    '/stores',
        headers: { 'Authorization' => 'Bearer caller-override', 'X-Custom' => 'value' }
      )

      expect(stub).to have_been_requested
    end
  end

  context 'query params' do
    it 'passes query_params to the HTTP layer' do
      stub = stub_request(:get, "#{api_url}/stores")
        .with(query: { 'page_size' => '25' })
        .to_return(
          status: 200,
          body: { stores: [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      subject.execute_api_request(
        method:       :get,
        path:         '/stores',
        query_params: { page_size: 25 }
      )

      expect(stub).to have_been_requested
    end
  end

  context 'error responses' do
    it 'raises ApiError for non-2xx responses' do
      stub_request(:get, "#{api_url}/stores/does-not-exist")
        .to_return(
          status: 404,
          body: { code: 'store_id_not_found' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect {
        subject.execute_api_request(method: :get, path: '/stores/does-not-exist')
      }.to raise_error(OpenFga::ApiError)
    end
  end
end
