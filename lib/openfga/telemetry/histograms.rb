# frozen_string_literal: true

module OpenFga
  module Telemetry
    module Histograms
      REQUEST_DURATION = Histogram.new(
        name: 'fga-client.request.duration',
        description: 'The total elapsed time (in milliseconds) for the complete request/response cycle.',
        unit: 'ms'
      )

      QUERY_DURATION = Histogram.new(
        name: 'fga-client.query.duration',
        description: 'The server-side query duration (in milliseconds) as reported by the FGA server.',
        unit: 'ms'
      )

      HTTP_REQUEST_DURATION = Histogram.new(
        name: 'fga-client.http.request.duration',
        description: 'The duration (in milliseconds) of each individual HTTP request, including retries.',
        unit: 'ms'
      )
    end
  end
end
