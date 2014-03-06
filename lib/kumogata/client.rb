class Kumogata::Client
  def initialize(options)
    @options = options
    @options = Hashie::Mash.new(@options) unless @options.kind_of?(Hashie::Mash)
    @cloud_formation = AWS::CloudFormation.new
  end

  def create(path_or_url, stack_name = nil)
    @options.delete_stack = false if stack_name
    template = open_template(path_or_url)

    if @options.delete_stack?
      template['Resources'].each do |k, v|
        v['DeletionPolicy'] = 'Retain'
      end
    end

    create_stack(template, stack_name)
    nil
  end

  def validate(path_or_url)
    template = open_template(path_or_url)
    validate_template(template)
    nil
  end

  def convert(path_or_url)
    template = open_template(path_or_url)

    if ruby_template?(path_or_url)
      JSON.pretty_generate(template)
    else
      devaluate_template(template).chomp
    end
  end

  def update(path_or_url, stack_name)
    template = open(path_or_url) do |f|
      evaluate_template(f)
    end

    update_stack(template, stack_name)
    nil
  end

  def delete(stack_name)
    if @options.force? or agree("Are you sure you want to delete `#{stack_name}`? ".yellow)
      delete_stack(stack_name)
    end

    nil
  end

  def list(stack_name = nil)
    stacks = describe_stacks(stack_name)
    JSON.pretty_generate(stacks)
  end

  def export(stack_name)
    template = export_template(stack_name)
    devaluate_template(template).chomp
  end

  def show_outputs(stack_name)
    outputs = describe_outputs(stack_name)
    JSON.pretty_generate(outputs)
  end

  def show_resources(stack_name)
    resources = describe_resources(stack_name)
    JSON.pretty_generate(resources)
  end

  def diff(path_or_url1, path_or_url2)
    templates = [path_or_url1, path_or_url2].map do |path_or_url|
      template = open_template(path_or_url)
      JSON.pretty_generate(template)
    end

    diff_opts = '-U 3'
    opts = {:include_diff_info => true, :diff => diff_opts}
    diff_opts << ' -w' if @options.ignore_all_space?

    diff = Diffy::Diff.new(*templates, opts).to_s
    diff.sub(/^(\e\[\d+m)?\-\-\-(\s+)(\S+)/m) { "#{$1}---#{$2}#{path_or_url1}"}
        .sub(/^(\e\[\d+m)?\+\+\+(\s+)(\S+)/m) { "#{$1}+++#{$2}#{path_or_url2}"}
  end

  private ###########################################################

  def open_template(path_or_url)
    open(path_or_url) do |f|
      if ruby_template?(path_or_url)
        evaluate_template(f)
      else
        JSON.parse(f.read)
      end
    end
  end

  def ruby_template?(path_or_url)
    File.extname(path_or_url) == '.rb'
  end

  def evaluate_template(template)
    key_converter = proc do |key|
      key = key.to_s
      key.gsub!('__', '::') if @options.replace_underscore?
      key
    end

    value_converter = proc do |v|
      case v
      when Hash, Array
        v
      else
        v.to_s
      end
    end

    Dslh.eval(template.read, {
      :key_conv   => key_converter,
      :value_conv => value_converter,
      :scope_hook => proc {|scope|
        define_template_func(scope, template.path)
      },
      :filename   => template.path,
    })
  end

  def devaluate_template(template)
    exclude_key = proc do |k|
      k = k.to_s.gsub('::', '__')
      k !~ /\A[_a-z]\w+\Z/i and k !~ %r|\A/\S*\Z|
    end

    key_conv = proc do |k|
      k = k.to_s

      if k =~ %r|\A/\S*\Z|
        proc do |v, nested|
          if nested
            "_path(#{k.inspect}) #{v}"
          else
            "_path #{k.inspect}, #{v}"
          end
        end
      else
        k.gsub('::', '__')
      end
    end

    value_conv = proc do |v|
      if v.kind_of?(String) and v =~ /\A(?:0|[1-9]\d*)\Z/
        v.to_i
      else
        v
      end
    end

    Dslh.deval(template, :key_conv => key_conv, :value_conv => value_conv, :exclude_key => exclude_key)
  end

  def define_template_func(scope, path_or_url)
    scope.instance_eval(<<-EOS)
      def _include(file)
        path = file.dup

        unless path =~ %r|\\A/| or path =~ %r|\\A\\w+://|
          path = File.expand_path(File.join(File.dirname(#{path_or_url.inspect}), path))
        end

        open(path) {|f| instance_eval(f.read) }
      end

      def _path(path, value = nil, &block)
        if block
          value = Dslh::ScopeBlock.nest(binding, 'block')
        end

        @__hash__[path] = value
      end
    EOS
  end

  def create_stack(template, stack_name)
    stack_name = stack_name || 'kumogata-' + UUIDTools::UUID.timestamp_create

    Kumogata.logger.info("Creating stack: #{stack_name}".cyan)
    stack = @cloud_formation.stacks.create(stack_name, template.to_json, build_create_options)

    unless while_in_progress(stack, 'CREATE_COMPLETE')
      errmsgs = ['Create failed']
      errmsgs << stack_name
      errmsgs << sstack.tatus_reason if stack.status_reason
      raise errmsgs.join(': ')
    end

    outputs = outputs_for(stack)
    summaries = resource_summaries_for(stack)

    if @options.delete_stack?
      delete_stack(stack_name)
    end

    output_result(stack_name, outputs, summaries)
  end

  def update_stack(template, stack_name)
    stack = @cloud_formation.stacks[stack_name]
    stack.status
    stack.update(build_update_options(template.to_json))

    Kumogata.logger.info("Updating stack: #{stack_name}".green)

    unless while_in_progress(stack, 'UPDATE_COMPLETE')
      errmsgs = ['Update failed']
      errmsgs << stack_name
      errmsgs << sstack.tatus_reason if stack.status_reason
      raise errmsgs.join(': ')
    end

    outputs = outputs_for(stack)
    summaries = resource_summaries_for(stack)
    output_result(stack_name, outputs, summaries)
  end

  def delete_stack(stack_name)
    stack = @cloud_formation.stacks[stack_name]
    stack.status

    Kumogata.logger.info("Deleting stack: #{stack_name}".red)
    stack.delete

    completed = false

    begin
      completed = while_in_progress(stack, 'DELETE_COMPLETE')
    rescue AWS::CloudFormation::Errors::ValidationError
      # Handle `Stack does not exist`
      completed = true
      Kumogata.logger.info('Successfully')
    end

    unless completed
      errmsgs = ['Delete failed']
      errmsgs << stack_name
      errmsgs << sstack.tatus_reason if stack.status_reason
      raise errmsgs.join(': ')
    end
  end

  def describe_stacks(stack_name)
    AWS.memoize do
      stacks = @cloud_formation.stacks
      stacks = stacks.select {|i| i.name == stack_name } if stack_name

      stacks.map do |stack|
        {
          'StackName'    => stack.name,
          'CreationTime' => stack.creation_time,
          'StackStatus'  => stack.status,
          'Description'  => stack.description,
        }
      end
    end
  end

  def export_template(stack_name)
    stack = @cloud_formation.stacks[stack_name]
    stack.status
    JSON.parse(stack.template)
  end

  def describe_outputs(stack_name)
    AWS.memoize do
      stack = @cloud_formation.stacks[stack_name]
      stack.status
      outputs_for(stack)
    end
  end

  def describe_resources(stack_name)
    AWS.memoize do
      stack = @cloud_formation.stacks[stack_name]
      stack.status
      resource_summaries_for(stack)
    end
  end

  def while_in_progress(stack, complete_status)
    while stack.status =~ /_IN_PROGRESS\Z/
      print '.'.intense_black unless @options.debug?
      sleep 1
    end

    completed = (stack.status == complete_status)
    Kumogata.logger.info(completed ? 'Successfully' : 'Failed')
    return completed
  end

  def build_create_options
    opts = {}
    add_parameters(opts)

    [:capabilities, :disable_rollback, :notify, :timeout].each do |k|
      opts[k] = @options[k] if @options[k]
    end

    return opts
  end

  def build_update_options(template)
    opts = {:template => template}
    add_parameters(opts)
    return opts
  end

  def add_parameters(hash)
    if @options.parameters?
      parameters = {}

      @options.parameters.each do |i|
        key, value = i.split('=', 2)
        parameters[key] = value
      end

      hash[:parameters] = parameters
    end
  end

  def validate_template(template)
    result = @cloud_formation.validate_template(template.to_json)

    if result[:code]
      raise result.values_at(:code, :message).join(': ')
    end

    Kumogata.logger.info('Template validated successfully'.green)
  end

  def outputs_for(stack)
    outputs_hash = {}

    stack.outputs.each do |output|
      outputs_hash[output.key] = output.value
    end

    return outputs_hash
  end

  def resource_summaries_for(stack)
    stack.resource_summaries.map do |summary|
      summary_hash = {}

      [
        :logical_resource_id,
        :physical_resource_id,
        :resource_type,
        :resource_status,
        :resource_status_reason,
        :last_updated_timestamp
      ].each do |k|
        camelcase = k.to_s.split(/[-_]/).map {|i|
          i[0, 1].upcase + i[1..-1].downcase
        }.join

        summary_hash[camelcase] = summary[k]
      end

      summary_hash
    end
  end

  def output_result(stack_name, outputs, summaries)
    puts <<-EOS

Outputs:
#{JSON.pretty_generate(outputs)}

Stack Resource Summaries:
#{JSON.pretty_generate(summaries)}

(Save to `#{@options.result_log}`)
    EOS

    open(@options.result_log, 'wb') do |f|
      f.puts JSON.pretty_generate({
        'StackName' => stack_name,
        'Outputs' => outputs,
        'StackResourceSummaries' => summaries,
      })
    end
  end
end
