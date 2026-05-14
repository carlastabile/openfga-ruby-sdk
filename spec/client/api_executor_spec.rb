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

  # --- input validation ---

  it 'raises ArgumentError when method is missing' do
    expect { subject.execute_api_request(path: '/stores') }
      .to raise_error(ArgumentError)
  end

  it 'raises ArgumentError when path is empty' do
    expect { subject.execute_api_request(method: :get, path: '') }
      .to raise_error(ArgumentError, /path is required/)
  end

  # --- return value ---

  it 'returns an ApiExecutorResponse with data, status, and headers' do
    stub_request(:get, "#{api_url}/stores")
      .to_return(
        status: 200,
        body: { stores: [] }.to_json,
        headers: { 'Content-Type' => 'application/json', 'X-Request-Id' => 'abc' }
      )

    resp = subject.execute_api_request(method: :get, path: '/stores')

    expect(resp).to be_a(OpenFga::ApiExecutorResponse)
    expect(resp.status).to   eq(200)
    expect(resp.data).to     eq({ stores: [] })
    expect(resp.headers).to  include('X-Request-Id' => 'abc')
    expect(resp.success?).to be(true)
  end

  it 'returns nil data for a 204 No Content response' do
    stub_request(:delete, "#{api_url}/stores/#{store_id}")
      .to_return(status: 204, body: '', headers: {})

    resp = subject.execute_api_request(
      method:      :delete,
      path:        '/stores/{store_id}',
      path_params: { store_id: }
    )

    expect(resp.status).to eq(204)
    expect(resp.data).to   be_nil
    expect(resp.success?).to be(true)
  end

  # --- HTTP methods ---

  it 'sends a PUT request' do
    stub = stub_request(:put, "#{api_url}/stores/#{store_id}")
      .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

    subject.execute_api_request(
      method:      :put,
      path:        '/stores/{store_id}',
      path_params: { store_id: },
      body:        { name: 'updated' }
    )

    expect(stub).to have_been_requested
  end

  it 'sends a PATCH request' do
    stub = stub_request(:patch, "#{api_url}/stores/#{store_id}")
      .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

    subject.execute_api_request(
      method:      :patch,
      path:        '/stores/{store_id}',
      path_params: { store_id: },
      body:        { name: 'patched' }
    )

    expect(stub).to have_been_requested
  end

  it 'sends a DELETE request' do
    stub = stub_request(:delete, "#{api_url}/stores/#{store_id}")
      .to_return(status: 204, body: '', headers: {})

    subject.execute_api_request(
      method:      :delete,
      path:        '/stores/{store_id}',
      path_params: { store_id: }
    )

    expect(stub).to have_been_requested
  end

  it 'accepts method as a string' do
    stub = stub_request(:get, "#{api_url}/stores")
      .to_return(status: 200, body: { stores: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    subject.execute_api_request(method: 'GET', path: '/stores')

    expect(stub).to have_been_requested
  end

  # --- path param substitution ---

  context 'path params' do
    it 'substitutes a single {placeholder} and CGI-encodes the value' do
      stub = stub_request(:post, "#{api_url}/stores/#{store_id}/check")
        .to_return(status: 200, body: { allowed: true }.to_json, headers: { 'Content-Type' => 'application/json' })

      resp = subject.execute_api_request(
        method:      :post,
        path:        '/stores/{store_id}/check',
        path_params: { store_id: },
        body:        { tuple_key: { user: 'user:anne', relation: 'reader', object: 'doc:1' } }
      )

      expect(stub).to have_been_requested
      expect(resp.data[:allowed]).to be(true)
    end

    it 'substitutes multiple placeholders' do
      model_id = '01G50QVV17PECNVAHX1GG4Y5NC'
      stub = stub_request(:get, "#{api_url}/stores/#{store_id}/authorization-models/#{model_id}")
        .to_return(status: 200, body: { authorization_model: {} }.to_json, headers: { 'Content-Type' => 'application/json' })

      subject.execute_api_request(
        method:      :get,
        path:        '/stores/{store_id}/authorization-models/{model_id}',
        path_params: { store_id:, model_id: }
      )

      expect(stub).to have_been_requested
    end

    it 'accepts symbol keys in path_params' do
      stub = stub_request(:get, "#{api_url}/stores/#{store_id}")
        .to_return(status: 200, body: { id: store_id }.to_json, headers: { 'Content-Type' => 'application/json' })

      subject.execute_api_request(
        method:      :get,
        path:        '/stores/{store_id}',
        path_params: { store_id: }
      )

      expect(stub).to have_been_requested
    end

    it 'URL-encodes special characters in path param values' do
      encoded = CGI.escape('store/with spaces')
      stub = stub_request(:get, "#{api_url}/stores/#{encoded}")
        .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      subject.execute_api_request(
        method:      :get,
        path:        '/stores/{store_id}',
        path_params: { store_id: 'store/with spaces' }
      )

      expect(stub).to have_been_requested
    end

    it 'raises URI::InvalidURIError when a placeholder has no matching path_param' do
      expect {
        subject.execute_api_request(method: :get, path: '/stores/{unknown_key}')
      }.to raise_error(URI::InvalidURIError)
    end
  end

  # --- auth header injection ---

  context 'auth headers' do
    it 'sends no Authorization header when credentials method is :none' do
      stub = stub_request(:get, "#{api_url}/stores")
        .to_return(status: 200, body: { stores: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

      subject.execute_api_request(method: :get, path: '/stores')

      expect(stub).to have_been_requested
      expect(stub.with(headers: { 'Authorization' => /.*/ })).not_to have_been_requested
    end

    it 'injects Authorization header when api_token credential is configured' do
      stub = stub_request(:get, "#{api_url}/stores")
        .with(headers: { 'Authorization' => 'Bearer my-token' })
        .to_return(status: 200, body: { stores: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

      subject_with_token.execute_api_request(method: :get, path: '/stores')

      expect(stub).to have_been_requested
    end

    it 'caller-supplied Authorization header overrides the SDK token' do
      stub = stub_request(:get, "#{api_url}/stores")
        .with(headers: { 'Authorization' => 'Bearer caller-override' })
        .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      subject_with_token.execute_api_request(
        method:  :get,
        path:    '/stores',
        headers: { 'Authorization' => 'Bearer caller-override' }
      )

      expect(stub).to have_been_requested
    end

    it 'merges caller-supplied headers with SDK auth headers' do
      stub = stub_request(:get, "#{api_url}/stores")
        .with(headers: { 'Authorization' => 'Bearer my-token', 'X-Custom' => 'value' })
        .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      subject_with_token.execute_api_request(
        method:  :get,
        path:    '/stores',
        headers: { 'X-Custom' => 'value' }
      )

      expect(stub).to have_been_requested
    end
  end

  # --- query params ---

  context 'query params' do
    it 'passes a single query param to the HTTP layer' do
      stub = stub_request(:get, "#{api_url}/stores")
        .with(query: { 'page_size' => '25' })
        .to_return(status: 200, body: { stores: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

      subject.execute_api_request(method: :get, path: '/stores', query_params: { page_size: 25 })

      expect(stub).to have_been_requested
    end

    it 'passes multiple query params to the HTTP layer' do
      stub = stub_request(:get, "#{api_url}/stores")
        .with(query: { 'page_size' => '10', 'continuation_token' => 'tok123' })
        .to_return(status: 200, body: { stores: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

      subject.execute_api_request(
        method:       :get,
        path:         '/stores',
        query_params: { page_size: 10, continuation_token: 'tok123' }
      )

      expect(stub).to have_been_requested
    end
  end

  # --- error responses ---

  context 'error responses' do
    it 'raises ApiError for a 404 response' do
      stub_request(:get, "#{api_url}/stores/does-not-exist")
        .to_return(status: 404, body: { code: 'store_id_not_found' }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect {
        subject.execute_api_request(method: :get, path: '/stores/does-not-exist')
      }.to raise_error(OpenFga::ApiError)
    end

    it 'raises ApiError for a 500 response' do
      stub_request(:post, "#{api_url}/stores/#{store_id}/check")
        .to_return(status: 500, body: { code: 'internal_error' }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect {
        subject.execute_api_request(
          method:      :post,
          path:        '/stores/{store_id}/check',
          path_params: { store_id: },
          body:        { tuple_key: {} }
        )
      }.to raise_error(OpenFga::ApiError)
    end

    it 'includes the HTTP status code in the raised ApiError' do
      stub_request(:get, "#{api_url}/stores/does-not-exist")
        .to_return(status: 404, body: { code: 'store_id_not_found' }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect {
        subject.execute_api_request(method: :get, path: '/stores/does-not-exist')
      }.to raise_error(OpenFga::ApiError) { |e| expect(e.code).to eq(404) }
    end
  end
end
