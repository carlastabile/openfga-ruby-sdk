module StubHelper

  def stub_request_with_response(method:, path:, status:, request_body:, response_body:)
    stub_request(method, path).
      with(
        body: request_body.to_json,
        headers: {
          'Accept'=>'application/json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type'=>'application/json',
          'User-Agent'=>'openfga-sdk ruby/0.0.1'
        }).to_return(
            status: status,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' })
  end
end