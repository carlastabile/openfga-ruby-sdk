# frozen_string_literal: true

module OpenFga
  module Telemetry
    module Attributes
      FGA_CLIENT_REQUEST_CLIENT_ID = Attribute.new(
        name: 'fga-client.request.client_id',
        description: 'The client ID associated with the request when using client credentials.',
        attr_key: :fga_client_request_client_id
      )

      FGA_CLIENT_REQUEST_METHOD = Attribute.new(
        name: 'fga-client.request.method',
        description: 'The FGA method/operation being called (e.g. Check, BatchCheck, Write).',
        attr_key: :fga_client_request_method
      )

      FGA_CLIENT_REQUEST_MODEL_ID = Attribute.new(
        name: 'fga-client.request.model_id',
        description: 'The authorization model ID used in the request.',
        attr_key: :fga_client_request_model_id
      )

      FGA_CLIENT_REQUEST_STORE_ID = Attribute.new(
        name: 'fga-client.request.store_id',
        description: 'The store ID used in the request.',
        attr_key: :fga_client_request_store_id
      )

      FGA_CLIENT_REQUEST_BATCH_CHECK_SIZE = Attribute.new(
        name: 'fga-client.request.batch_check_size',
        description: 'The number of checks in a BatchCheck request.',
        attr_key: :fga_client_request_batch_check_size
      )

      FGA_CLIENT_RESPONSE_MODEL_ID = Attribute.new(
        name: 'fga-client.response.model_id',
        description: 'The authorization model ID returned in the response.',
        attr_key: :fga_client_response_model_id
      )

      FGA_CLIENT_USER = Attribute.new(
        name: 'fga-client.user',
        description: 'The user from the check request tuple key.',
        attr_key: :fga_client_user
      )

      HTTP_HOST = Attribute.new(
        name: 'http.host',
        description: 'The host of the HTTP request.',
        attr_key: :http_host
      )

      HTTP_REQUEST_METHOD = Attribute.new(
        name: 'http.request.method',
        description: 'The HTTP method used for the request.',
        attr_key: :http_request_method
      )

      HTTP_RESPONSE_STATUS_CODE = Attribute.new(
        name: 'http.response.status_code',
        description: 'The HTTP response status code.',
        attr_key: :http_response_status_code
      )

      URL_SCHEME = Attribute.new(
        name: 'url.scheme',
        description: 'The URL scheme of the request (http or https).',
        attr_key: :url_scheme
      )

      URL_FULL = Attribute.new(
        name: 'url.full',
        description: 'The full URL of the request.',
        attr_key: :url_full
      )

      USER_AGENT_ORIGINAL = Attribute.new(
        name: 'user_agent.original',
        description: 'The user agent string of the SDK.',
        attr_key: :user_agent_original
      )
    end
  end
end
