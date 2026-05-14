require 'spec_helper'

describe OpenFga::SdkClient, '#execute_streaming_api_request' do
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

  let(:stream_path) { "#{api_url}/stores/#{store_id}/streamed-list-objects" }

  def ndjson(*objects)
    objects.map(&:to_json).join("\n") + "\n"
  end

  # --- input validation ---

  it 'raises ArgumentError when no block is given' do
    expect {
      subject.execute_streaming_api_request(
        method:      :post,
        path:        '/stores/{store_id}/streamed-list-objects',
        path_params: { store_id: }
      )
    }.to raise_error(ArgumentError, /block is required/)
  end

  it 'raises ArgumentError when method is omitted' do
    expect {
      subject.execute_streaming_api_request(path: '/stores') { |_| }
    }.to raise_error(ArgumentError)
  end

  it 'raises ArgumentError when path is empty' do
    expect {
      subject.execute_streaming_api_request(method: :post, path: '') { |_| }
    }.to raise_error(ArgumentError, /path is required/)
  end

  # --- return value ---

  it 'returns an ApiExecutorResponse with nil data and the HTTP status' do
    stub_request(:post, stream_path)
      .to_return(status: 200, body: 'chunk', headers: {})

    resp = subject.execute_streaming_api_request(
      method:      :post,
      path:        '/stores/{store_id}/streamed-list-objects',
      path_params: { store_id: }
    ) { |_| }

    expect(resp).to be_a(OpenFga::ApiExecutorResponse)
    expect(resp.status).to  eq(200)
    expect(resp.data).to    be_nil
    expect(resp.success?).to be(true)
  end

  # --- raw chunk yielding ---

  it 'yields the response body as a raw string chunk' do
    body = ndjson({ result: { object: 'document:1' } }, { result: { object: 'document:2' } })

    stub_request(:post, stream_path)
      .to_return(status: 200, body:, headers: {})

    received = []
    subject.execute_streaming_api_request(
      method:      :post,
      path:        '/stores/{store_id}/streamed-list-objects',
      path_params: { store_id: }
    ) { |chunk| received << chunk }

    expect(received).not_to be_empty
    expect(received.join).to eq(body)
  end

  it 'does not parse the chunk — that is left to the caller' do
    stub_request(:post, stream_path)
      .to_return(status: 200, body: "raw content\n", headers: {})

    received = []
    subject.execute_streaming_api_request(
      method:      :post,
      path:        '/stores/{store_id}/streamed-list-objects',
      path_params: { store_id: }
    ) { |chunk| received << chunk }

    expect(received.join).to include('raw content')
  end

  it 'does not yield when the response body is empty' do
    stub_request(:post, stream_path)
      .to_return(status: 200, body: '', headers: {})

    block_called = false
    subject.execute_streaming_api_request(
      method:      :post,
      path:        '/stores/{store_id}/streamed-list-objects',
      path_params: { store_id: }
    ) { |_| block_called = true }

    expect(block_called).to be(false)
  end

  # --- headers ---

  it 'does not set Accept automatically — caller must set it explicitly' do
    stub = stub_request(:post, stream_path)
      .to_return(status: 200, body: '', headers: {})

    subject.execute_streaming_api_request(
      method:      :post,
      path:        '/stores/{store_id}/streamed-list-objects',
      path_params: { store_id: }
    ) { |_| }

    expect(stub).to have_been_requested
    expect(stub.with(headers: { 'Accept' => 'application/x-ndjson' })).not_to have_been_requested
  end

  it 'forwards caller-supplied headers including Accept' do
    stub = stub_request(:post, stream_path)
      .with(headers: { 'Accept' => 'application/x-ndjson', 'X-Request-ID' => 'abc' })
      .to_return(status: 200, body: '', headers: {})

    subject.execute_streaming_api_request(
      method:      :post,
      path:        '/stores/{store_id}/streamed-list-objects',
      path_params: { store_id: },
      headers:     { 'Accept' => 'application/x-ndjson', 'X-Request-ID' => 'abc' }
    ) { |_| }

    expect(stub).to have_been_requested
  end

  # --- auth header injection ---

  it 'injects Authorization header when credentials are configured' do
    stub = stub_request(:post, stream_path)
      .with(headers: { 'Authorization' => 'Bearer my-token' })
      .to_return(status: 200, body: '', headers: {})

    subject_with_token.execute_streaming_api_request(
      method:      :post,
      path:        '/stores/{store_id}/streamed-list-objects',
      path_params: { store_id: }
    ) { |_| }

    expect(stub).to have_been_requested
  end

  # --- path params ---

  it 'substitutes path params into the URL' do
    stub = stub_request(:post, stream_path)
      .to_return(status: 200, body: '', headers: {})

    subject.execute_streaming_api_request(
      method:      :post,
      path:        '/stores/{store_id}/streamed-list-objects',
      path_params: { store_id: }
    ) { |_| }

    expect(stub).to have_been_requested
  end

  # --- query params ---

  it 'passes query_params to the HTTP layer' do
    stub = stub_request(:post, stream_path)
      .with(query: { 'consistency' => 'HIGHER_CONSISTENCY' })
      .to_return(status: 200, body: '', headers: {})

    subject.execute_streaming_api_request(
      method:       :post,
      path:         '/stores/{store_id}/streamed-list-objects',
      path_params:  { store_id: },
      query_params: { consistency: 'HIGHER_CONSISTENCY' }
    ) { |_| }

    expect(stub).to have_been_requested
  end

  # --- request body ---

  it 'sends the request body as JSON' do
    req_body = { type: 'document', relation: 'reader', user: 'user:anne' }

    stub = stub_request(:post, stream_path)
      .with(body: req_body.to_json)
      .to_return(status: 200, body: '', headers: {})

    subject.execute_streaming_api_request(
      method:      :post,
      path:        '/stores/{store_id}/streamed-list-objects',
      path_params: { store_id: },
      body:        req_body
    ) { |_| }

    expect(stub).to have_been_requested
  end

  # --- NDJSON auto-parsing (triggered by Accept header) ---

  context 'when Accept: application/x-ndjson is set' do
    it 'yields parsed Hashes instead of raw strings' do
      body = ndjson({ result: { object: 'repo:sdk' } }, { result: { object: 'repo:docs' } })

      stub_request(:post, stream_path)
        .to_return(status: 200, body:, headers: {})

      received = []
      subject.execute_streaming_api_request(
        method:      :post,
        path:        '/stores/{store_id}/streamed-list-objects',
        path_params: { store_id: },
        headers:     { 'Accept' => 'application/x-ndjson' }
      ) { |obj| received << obj }

      expect(received.length).to eq(2)
      expect(received[0]).to eq({ result: { object: 'repo:sdk' } })
      expect(received[1]).to eq({ result: { object: 'repo:docs' } })
    end

    it 'handles a single NDJSON object without a trailing newline' do
      stub_request(:post, stream_path)
        .to_return(status: 200, body: '{"result":{"object":"repo:sdk"}}', headers: {})

      received = []
      subject.execute_streaming_api_request(
        method:      :post,
        path:        '/stores/{store_id}/streamed-list-objects',
        path_params: { store_id: },
        headers:     { 'Accept' => 'application/x-ndjson' }
      ) { |obj| received << obj }

      expect(received).to eq([{ result: { object: 'repo:sdk' } }])
    end

    it 'does not yield when the body is empty' do
      stub_request(:post, stream_path)
        .to_return(status: 200, body: '', headers: {})

      block_called = false
      subject.execute_streaming_api_request(
        method:      :post,
        path:        '/stores/{store_id}/streamed-list-objects',
        path_params: { store_id: },
        headers:     { 'Accept' => 'application/x-ndjson' }
      ) { |_| block_called = true }

      expect(block_called).to be(false)
    end
  end

  # --- error responses ---

  it 'raises ApiError for non-2xx responses without calling the block' do
    stub_request(:post, stream_path)
      .to_return(status: 404, body: { code: 'store_id_not_found' }.to_json, headers: { 'Content-Type' => 'application/json' })

    block_called = false
    expect {
      subject.execute_streaming_api_request(
        method:      :post,
        path:        '/stores/{store_id}/streamed-list-objects',
        path_params: { store_id: }
      ) { |_| block_called = true }
    }.to raise_error(OpenFga::ApiError)

    expect(block_called).to be(false)
  end

  it 'includes the HTTP status code in the raised ApiError' do
    stub_request(:post, stream_path)
      .to_return(status: 403, body: { code: 'forbidden' }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect {
      subject.execute_streaming_api_request(
        method:      :post,
        path:        '/stores/{store_id}/streamed-list-objects',
        path_params: { store_id: }
      ) { |_| }
    }.to raise_error(OpenFga::ApiError) { |e| expect(e.code).to eq(403) }
  end
end
