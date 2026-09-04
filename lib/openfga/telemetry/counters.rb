# frozen_string_literal: true

module OpenFga
  module Telemetry
    module Counters
      CREDENTIALS_REQUEST = Counter.new(
        name: 'fga-client.credentials.request',
        description: 'The total number of times new access tokens have been requested using ClientCredentials.'
      )

      REQUEST_COUNT = Counter.new(
        name: 'fga-client.request.count',
        description: 'The total number of requests made by the FGA client.'
      )
    end
  end
end
