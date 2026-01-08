module OpenFga
  module_function

  def blank?(value)
    value.respond_to?(:empty?) ? value.empty? : !value
  end
end
