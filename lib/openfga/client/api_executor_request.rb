# frozen_string_literal: true

module OpenFga
  class ApiExecutorRequest
    attr_accessor :method, :path, :path_params, :query_params, :body, :headers

    def initialize(method:, path:, path_params: {}, query_params: {}, body: nil, headers: {})
      @method       = method
      @path         = path
      @path_params  = path_params  || {}
      @query_params = query_params || {}
      @body         = body
      @headers      = headers      || {}
    end

    def self.build
      req = new(method: nil, path: nil)
      yield req
      req
    end

    def validate!
      raise ArgumentError, "ApiExecutorRequest#method is required" if @method.nil?
      raise ArgumentError, "ApiExecutorRequest#path is required"   if @path.nil? || @path.empty?
    end
  end
end
