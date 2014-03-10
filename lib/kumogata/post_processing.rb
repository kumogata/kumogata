class Kumogata::PostProcessing
  TRIGGER_TIMING = [:create, :update]

  def initialize(options)
    @options = options
    @commands = {}

    @command_options = {
      :undent    => true,
      :trim_mode => nil,
    }
  end

  def fetch!(template)
    _post = template.delete(:_post)
    return unless _post

    options = _post[:options] || {}
    @command_options.merge(options)

    _post.fetch(:commands).each do |name, attrs|
      timing = [(attrs['after'] || TRIGGER_TIMING)].flatten.map {|i| i.to_sym }
      validate_timing(timing)
      command = attrs.fetch('command')

      @commands[name] = {
        :after   => timing,
        :command => command,
      }
    end
  end

  def run(timing, outputs)
    results = []

    @commands.each do |name, attrs|
      next unless attrs[:after].include?(timing)

      out, err, status = run_command(attrs[:command], outputs)
      results << print_command_result(name, out, err, status)
    end

    save_command_results(results) unless results.empty?
  end

  private

  def validate_timing(timing)
    timing.each do |t|
      unless TRIGGER_TIMING.include?(t)
        raise "Unknown post processing timing #{timing.inspect} in #{name}"
      end
    end
  end

  def run_command(command, outputs)
    command = command.undent if @command_options[:undent]
    trim_mode = @command_options[:trim_mode]

    scope = Object.new
    scope.instance_variable_set(:@__outputs__, outputs)

    command = scope.instance_eval(<<-EOS)
      def Key(name)
        @__outputs__[name]
      end

      ERB.new(#{command.inspect}, nil, #{trim_mode.inspect}).result(binding)
    EOS

    Open3.capture3(command)
  end

  def print_command_result(name, out, err, status)
    out ||= ''
    err ||= ''

    puts <<-EOS

---
Post Command: #{name.send(status.success? ? :green : :red)}
ExitStatus: #{status.to_i}
StdOut:
#{out.chomp}
StdErr:
#{err.chomp}
    EOS

    {name => {
      'ExitStatus' => status.to_i,
      'StdOut' => out,
      'StdErr' => err,
    }}
  end

  def save_command_results(results)
    puts <<-EOS

(Save to `#{@options.command_result_log}`)
    EOS

    open(@options.command_result_log, 'wb') do |f|
      f.puts JSON.pretty_generate(results)
    end
  end

  def validate_stack_name(stack_name)
    return unless stack_name

    unless /\A[a-zA-Z][-a-zA-Z0-9]*\Z/i =~ stack_name
      raise "1 validation error detected: Value '#{stack_name}' at 'stackName' failed to satisfy constraint: Member must satisfy regular expression pattern: [a-zA-Z][-a-zA-Z0-9]*"
    end
  end
end
