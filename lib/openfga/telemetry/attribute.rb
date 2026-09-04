# frozen_string_literal: true

module OpenFga
  module Telemetry
    Attribute = Struct.new(:name, :description, :attr_key, keyword_init: true)
  end
end
