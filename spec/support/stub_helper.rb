module StubHelper
  def stub_request_with_response(method:, path:, status:, headers: {}, request_body: nil, response_body: '')
    body = request_body.nil? ? '' : request_body.to_json

    stub_request(method, path).
      with(
        body:,
        headers: {
          'Accept' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
        }.merge(headers)).to_return(
          status:,
          body: response_body.to_json,
          headers: { 'Content-Type' => 'application/json' })
  end
end
