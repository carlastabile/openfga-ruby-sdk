# frozen_string_literal: true

module OpenFga
  module Telemetry
    Histogram = Struct.new(:name, :description, :unit, keyword_init: true)
  end
end
