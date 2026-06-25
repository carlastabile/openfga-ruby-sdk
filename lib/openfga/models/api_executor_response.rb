# frozen_string_literal: true

module OpenFga
  class ApiExecutorResponse
    attr_reader :data, :status, :headers

    def initialize(data:, status:, headers:)
      @data    = data
      @status  = status
      @headers = headers
    end

    def success?
      !@status.nil? && @status >= 200 && @status < 300
    end
  end
end
