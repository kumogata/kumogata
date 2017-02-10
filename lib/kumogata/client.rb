class Kumogata::Client
  def initialize(options)
    @options = options
    @options = Hashie::Mash.new(@options) unless @options.kind_of?(Hashie::Mash)
    @cloud_formation = AWS::CloudFormation.new
    @outputs_filter = Kumogata::OutputsFilter.new(@options)
    @post_processing = Kumogata::PostProcessing.new(@options)
  end

  def create(path_or_url, stack_name = nil)
    validate_stack_name(stack_name)

    @options.delete_stack = false if stack_name
    template = open_template(path_or_url)
    update_deletion_policy(template)
    add_encryption_password(template)

    outputs = create_stack(template, stack_name)

    unless @options.detach?
      @outputs_filter.filter!(outputs)
      @post_processing.run(:create, outputs)
      outputs
    end
  end

  def validate(path_or_url)
    template = open_template(path_or_url)
    add_encryption_password_for_validation(template)
    validate_template(template)
    true
  end

  def convert(path_or_url)
    template = open_template(path_or_url)
    output_format = @options.output_format

    unless output_format
      output_format = case @options.format || guess_format(path_or_url)
                      when :ruby then :json
                      when :json then :ruby
                      when :yaml then :json
                      when :js then :json
                      when :json5 then :json
                      end
    end

    case output_format
    when :ruby
      devaluate_template(template).chomp.colorize_as(:ruby)
    when :json, :json5
      JSON.pretty_generate(template).colorize_as(:json)
    when :yaml
      YAML.dump(template).colorize_as(:yaml)
    when :js
      '(' + JSON.pretty_generate(template).colorize_as(:json) + ')'
    when :coffee
      raise 'Output to CoffeeScript is not implemented'
    end
  end

  def update(path_or_url, stack_name)
    validate_stack_name(stack_name)

    @options.delete_stack = false
    template = open_template(path_or_url)
    update_deletion_policy(template, :update_metadate => true)
    add_encryption_password(template)

    outputs = update_stack(template, stack_name)

    unless @options.detach?
      @outputs_filter.filter!(outputs)
      @post_processing.run(:update, outputs)
      outputs
    end
  end

  def delete(stack_name)
    validate_stack_name(stack_name)

    if @options.force? or agree("Are you sure you want to delete `#{stack_name}`? ".yellow)
      delete_stack(stack_name)
    end

    unless @options.detach?
      true
    end
  end

  def list(stack_name = nil)
    validate_stack_name(stack_name)

    stacks = describe_stacks(stack_name)
    JSON.pretty_generate(stacks).colorize_as(:json)
  end

  def export(stack_name)
    validate_stack_name(stack_name)

    template = export_template(stack_name)
    format = @options.format || :ruby

    case format
    when :ruby
      devaluate_template(template).chomp.colorize_as(:ruby)
    when :json
      JSON.pretty_generate(template).colorize_as(:json)
    else
      raise "Unknown format: #{format}"
    end
  end

  def show_events(stack_name)
    validate_stack_name(stack_name)

    events = describe_events(stack_name)
    JSON.pretty_generate(events).colorize_as(:json)
  end

  def show_outputs(stack_name)
    validate_stack_name(stack_name)

    outputs = describe_outputs(stack_name)
    JSON.pretty_generate(outputs).colorize_as(:json)
  end

  def show_resources(stack_name)
    validate_stack_name(stack_name)

    resources = describe_resources(stack_name)
    JSON.pretty_generate(resources).colorize_as(:json)
  end

  def diff(path_or_url1, path_or_url2)
    templates = [path_or_url1, path_or_url2].map do |path_or_url|
      template = nil

      if path_or_url =~ %r|\Astack://(.*)|
        stack_name = $1 || ''
        validate_stack_name(stack_name)
        template = export_template(stack_name)
      else
        template = open_template(path_or_url)
      end

      JSON.pretty_generate(template)
    end

    diff_opts = @options.ignore_all_space? ? '-uw' : '-u'
    opts = {:include_diff_info => true, :diff => diff_opts}
    diff = Diffy::Diff.new(*templates, opts).to_s

    diff.sub(/^(\e\[\d+m)?\-\-\-(\s+)(\S+)/m) { "#{$1}---#{$2}#{path_or_url1}"}
        .sub(/^(\e\[\d+m)?\+\+\+(\s+)(\S+)/m) { "#{$1}+++#{$2}#{path_or_url2}"}
  end

  private ###########################################################

  def open_template(path_or_url)
    format = @options.format || guess_format(path_or_url)

    block = proc do |f|
      case format
      when :ruby
        evaluate_template(f, path_or_url)
      when :json
        JSON.parse(f.read)
      when :yaml
        parsed = YAML.load(f.read)
        Kumogata::Utils.stringify(parsed)
      when :js
        obj = V8::Context.new.eval(f.read)

        unless obj.instance_of?(V8::Object)
          raise "Invalid JavaScript template. Please return Object: #{path_or_url}"
        end

        Kumogata::Utils.stringify(obj.to_hash)
      when :coffee
        completed = CoffeeScript.compile(f.read)
        obj = V8::Context.new.eval(completed)

        unless obj.instance_of?(V8::Object)
          raise "Invalid CoffeeScript template. Please return Object: #{path_or_url}"
        end

        Kumogata::Utils.stringify(obj.to_hash)
      when :json5
        parsed = JSON5.parse(f.read)
        Kumogata::Utils.stringify(parsed)
      else
        raise "Unknown format: #{format}"
      end
    end

    if path_or_url == '-'
      block.call($stdin)
    else
      open(path_or_url, &block)
    end
  end

  def guess_format(path_or_url)
    case File.extname(path_or_url)
    when '.rb'
      :ruby
    when '.json'
      :json
    when '.yml', '.yaml'
      :yaml
    when '.js'
      :js
    when '.coffee'
      :coffee
    when '.json5'
      :json5
    else
      :json
    end
  end

  def evaluate_template(template, path_or_url)
    key_converter = proc do |key|
      key = key.to_s
      unless @options.skip_replace_underscore?
        key.gsub!('_', ':')
        key.gsub!('__', '::')
      end
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

    template = Dslh.eval(template.read, {
      :key_conv   => key_converter,
      :value_conv => value_converter,
      :scope_hook => proc {|scope|
        define_template_func(scope, path_or_url)
      },
      :filename   => path_or_url,
    })

    @outputs_filter.fetch!(template)
    @post_processing.fetch!(template)

    return template
  end

  def evaluate_after_trigger(template)
    triggers = template.delete('_after')
    return {} unless triggers
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
      def _include(file, args = {})
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

      def _outputs_filter(&block)
        @__hash__[:_outputs_filter] = block
      end

      def _post(options = {}, &block)
        commands = Dslh::ScopeBlock.nest(binding, 'block')

        @__hash__[:_post] = {
          :options  => options,
          :commands => commands,
        }
      end
    EOS
  end

  def create_stack(template, stack_name)
    unless stack_name
      user_host = Kumogata::Utils.get_user_host

      stack_name = ['kumogata']
      stack_name << user_host if user_host
      stack_name << UUIDTools::UUID.timestamp_create

      stack_name = stack_name.join('-')
      stack_name.gsub!(/[^-a-zA-Z0-9]+/, '-')
    end

    Kumogata.logger.info("Creating stack: #{stack_name}".cyan)
    stack = @cloud_formation.stacks.create(stack_name, template.to_json, build_create_options)

    return if @options.detach?

    event_log = {}

    unless while_in_progress(stack, 'CREATE_COMPLETE', event_log)
      errmsgs = ['Create failed']
      errmsgs << stack_name
      errmsgs << stack.status_reason if stack.status_reason
      raise errmsgs.join(': ')
    end

    outputs = outputs_for(stack)
    summaries = resource_summaries_for(stack)

    if @options.delete_stack?
      delete_stack(stack_name)
    end

    output_result(stack_name, outputs, summaries)

    return outputs
  end

  def update_stack(template, stack_name)
    stack = @cloud_formation.stacks[stack_name]
    stack.status

    Kumogata.logger.info("Updating stack: #{stack_name}".green)
    event_log = create_event_log(stack)
    stack.update(build_update_options(template.to_json))

    return if @options.detach?

    unless while_in_progress(stack, 'UPDATE_COMPLETE', event_log)
      errmsgs = ['Update failed']
      errmsgs << stack_name
      errmsgs << stack.status_reason if stack.status_reason
      raise errmsgs.join(': ')
    end

    outputs = outputs_for(stack)
    summaries = resource_summaries_for(stack)
    output_result(stack_name, outputs, summaries)

    return outputs
  end

  def delete_stack(stack_name)
    stack = @cloud_formation.stacks[stack_name]
    stack.status

    Kumogata.logger.info("Deleting stack: #{stack_name}".red)
    event_log = create_event_log(stack)
    stack.delete

    return if @options.detach?

    completed = false

    begin
      completed = while_in_progress(stack, 'DELETE_COMPLETE', event_log)
    rescue AWS::CloudFormation::Errors::ValidationError
      # Handle `Stack does not exist`
      completed = true
      Kumogata.logger.info('Success')
    end

    unless completed
      errmsgs = ['Delete failed']
      errmsgs << stack_name
      errmsgs << stack.status_reason if stack.status_reason
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

  def describe_events(stack_name)
    AWS.memoize do
      stack = @cloud_formation.stacks[stack_name]
      stack.status
      events_for(stack)
    end
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

  def while_in_progress(stack, complete_status, event_log)
    # XXX: Status does not change if you have been memoized.
    #      Should be forcibly disabled memoization?
    while stack.status =~ /_IN_PROGRESS\Z/
      print_event_log(stack, event_log)
      sleep 1
    end

    print_event_log(stack, event_log)
    completed = (stack.status == complete_status)
    Kumogata.logger.info(completed ? 'Success' : 'Failure')
    return completed
  end

  def print_event_log(stack, event_log)
    events_for(stack).sort_by {|i| i['Timestamp'] }.each do |event|
      event_id = event['EventId']

      unless event_log[event_id]
        event_log[event_id] = event

        timestamp = event['Timestamp']
        summary = {}

        ['LogicalResourceId', 'ResourceStatus', 'ResourceStatusReason'].map do |k|
          summary[k] = event[k]
        end

        puts [
          timestamp.getlocal.strftime('%Y/%m/%d %H:%M:%S %Z'),
          summary.to_json.colorize_as(:json),
        ].join(': ')
      end
    end
  end

  def create_event_log(stack)
    event_log = {}

    events_for(stack).sort_by {|i| i['Timestamp'] }.each do |event|
      event_id = event['EventId']
      event_log[event_id] = event
    end

    return event_log
  end

  def build_create_options
    opts = {}
    add_parameters(opts)

    [:capabilities, :disable_rollback, :notify, :timeout,
     :stack_policy_body, :stack_policy_url].each do |k|
      opts[k] = @options[k] if @options[k]
    end

    return opts
  end

  def build_update_options(template)
    opts = {:template => template}
    add_parameters(opts)

    [:capabilities, :stack_policy_body, :stack_policy_url].each do |k|
      opts[k] = @options[k] if @options[k]
    end

    return opts
  end

  def add_parameters(hash)
    if @options.parameters? and not @options.parameters.empty?
      parameters = {}

      enc_params = @options.encrypt_parameters
      passwd = @options.encryption_password || Kumogata::Crypt.mkpasswd(16)

      @options.parameters.each do |key, value|
        if enc_params and (enc_params.include?('*') or enc_params.include?(key))
          value = Kumogata::Crypt.encrypt(passwd, value)
        end

        parameters[key] = value
      end

      if @options.encrypt_parameters? and not @options.skip_send_password?
        parameters[Kumogata::ENCRYPTION_PASSWORD] = passwd.encode64
      end

      hash[:parameters] = parameters
    end
  end

  def update_deletion_policy(template, options = {})
    if @options.delete_stack? or @options.deletion_policy_retain?
      template['Resources'].each do |k, v|
        next if /\AAWS::CloudFormation::/ =~ v['Type']
        v['DeletionPolicy'] ||= 'Retain'

        if options[:update_metadate]
          v['Metadata'] ||= {}
          v['Metadata']['DeletionPolicyUpdateKeyForKumogata'] = "DeletionPolicyUpdateValueForKumogata#{Time.now.to_i}"
        end
      end
    end
  end

  def add_encryption_password(template)
    if @options.encrypt_parameters? and not @options.skip_send_password?
      template['Parameters'] ||= {}

      template['Parameters'][Kumogata::ENCRYPTION_PASSWORD] = {
        'Type'   => 'String',
        'NoEcho' => 'true',
      }
    end
  end

  def add_encryption_password_for_validation(template)
    template['Parameters'] ||= {}

    template['Parameters'][Kumogata::ENCRYPTION_PASSWORD] ||= {
      'Type' => 'String',
      'Default' => "(#{Kumogata::ENCRYPTION_PASSWORD})",
    }
  end

  def validate_template(template)
    result = @cloud_formation.validate_template(template.to_json)

    if result[:code]
      raise result.values_at(:code, :message).join(': ')
    end

    Kumogata.logger.info('Template validated successfully'.green)

    if @options.verbose
      Kumogata.logger.info(JSON.pretty_generate(JSON.parse(result.to_json)).colorize_as(:json))
    end
  end

  def events_for(stack)
    stack.events.map do |event|
      event_hash = {}

      [
        :event_id,
        :logical_resource_id,
        :physical_resource_id,
        :resource_properties,
        :resource_status,
        :resource_status_reason,
        :resource_type,
        :stack_id,
        :stack_name,
        :timestamp,
      ].each do |k|
        event_hash[Kumogata::Utils.camelize(k)] = event.send(k)
      end

      event_hash
    end
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
        summary_hash[Kumogata::Utils.camelize(k)] = summary[k]
      end

      summary_hash
    end
  end

  def output_result(stack_name, outputs, summaries)
    puts <<-EOS

Stack Resource Summaries:
#{JSON.pretty_generate(summaries).colorize_as(:json)}

Outputs:
#{JSON.pretty_generate(outputs).colorize_as(:json)}
EOS

    if @options.result_log?
      puts <<-EOS

(Save to `#{@options.result_log}`)
      EOS

      open(@options.result_log, 'wb') do |f|
        f.puts JSON.pretty_generate({
          'StackName' => stack_name,
          'StackResourceSummaries' => summaries,
          'Outputs' => outputs,
        })
      end
    end
  end

  def validate_stack_name(stack_name)
    return unless stack_name

    unless /\A[a-zA-Z][-a-zA-Z0-9]*\Z/i =~ stack_name
      raise "1 validation error detected: Value '#{stack_name}' at 'stackName' failed to satisfy constraint: Member must satisfy regular expression pattern: [a-zA-Z][-a-zA-Z0-9]*"
    end
  end
end
