class Kumogata::OutputsFilter
  def initialize(options)
    @options = options
  end

  def fetch!(template)
    @filter = template.delete(:_outputs_filter)
  end

  def filter!(outputs)
    @filter.call(outputs) if @filter
    return outputs
  end
end
