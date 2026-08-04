# frozen_string_literal: true

module OpenFga
  module Telemetry
    Counter = Struct.new(:name, :description, keyword_init: true)
  end
end
