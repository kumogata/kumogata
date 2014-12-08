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

    outputs = template['Outputs'] || {}

    _post.fetch(:commands).each do |name, attrs|
      unless attrs.kind_of?(Hash) and attrs['command']
        raise "Invalid post processing: #{name} => #{attrs.inspect}"
      end

      timing = [(attrs['after'] || [:create])].flatten.map {|i| i.to_sym }
      command = attrs['command']

      validate_timing(name, timing)
      validate_command_template(name, command, outputs)

      @commands[name] = {
        :after   => timing,
        :command => command,
      }

      if (ssh = attrs['ssh'])
        validate_ssh(name, ssh, outputs)
        @commands[name][:ssh] = ssh
      end
    end
  end

  def run(timing, outputs)
    results = []

    @commands.each do |name, attrs|
      next unless attrs[:after].include?(timing)

      print_command(name)
      out, err, status = run_command(attrs, outputs)
      print_command_result(out, err, status)

      results << {
        name => {
          'ExitStatus' => status.to_i,
          'StdOut' => out.force_encoding('UTF-8'),
          'StdErr' => err.force_encoding('UTF-8'),
        }
      }
    end

    if @options.command_result_log? and not results.empty?
      save_command_results(results)
    end
  end

  private

  def validate_timing(name, timing)
    timing.each do |t|
      unless TRIGGER_TIMING.include?(t)
        raise "Unknown post processing timing: #{name} => #{timing.inspect}"
      end
    end
  end

  def validate_ssh(name, ssh, outputs)
    host, user, options = ssh.values_at('host', 'user', 'options')

    unless host and user
      raise "`host` and `user` is required for post processing ssh: #{name}"
    end

    if host.kind_of?(Hash)
      if host.keys != ['Key']
        raise "Invalid post processing ssh host: #{name} => #{host.inspect}"
      end

      host_key, host_value = host.first
      ssh['host'] = "<%= #{host_key} #{host_value.to_s.inspect} %>"
    else
      ssh['host'] = host.to_s
    end

    validate_command_template(name, ssh['host'], outputs)

    if user.kind_of?(Hash)
      if user.keys != ['Key']
        raise "Invalid post processing ssh user: #{name} => #{user.inspect}"
      end

      user_key, user_value = user.first
      ssh['user'] = "<%= #{user_key} #{user_value.to_s.inspect} %>"
    else
      ssh['user'] = user.to_s
    end

    validate_command_template(name, ssh['user'], outputs)

    if options and not options.kind_of?(Hash)
      raise "Invalid post processing ssh options: #{name} => #{options.inspect}"
    end

    ssh['request_pty'] = !!((ssh['request_pty'] || true).to_s =~ /\Atrue\Z/)
  end

  def run_command(attrs, outputs)
    command, ssh = attrs.values_at(:command, :ssh)

    if ssh
      run_ssh_command(ssh, command, outputs)
    else
      run_shell_command(command, outputs)
    end
  end

  def run_ssh_command(ssh, command, outputs)
    host, user, options = ssh.values_at('host', 'user', 'options')
    host = evaluate_command_template(host, outputs)
    user = evaluate_command_template(user, outputs)
    args = [host, user]
    args << ssh['options'] if ssh['options']

    command = evaluate_command_template(command, outputs)

    connect_tries = (ssh['connect_tries'] || 36).to_i
    retry_interval = (ssh['retry_interval'] || 5).to_i

    stderr_orig = nil
    ssh_exec_opts = {:request_pty => ssh['request_pty']}

    begin
      stderr_orig = STDERR.dup
      STDERR.reopen('/dev/null', 'w')

      Retryable.retryable(:tries => connect_tries, :sleep => retry_interval) do
        begin
          Net::SSH.start(*args) {|ssh| ssh.exec!('echo') }
        rescue Net::SSH::HostKeyMismatch => e
          e.remember_host!
          retry
        end
      end

      Net::SSH.start(*args) {|ssh| ssh_exec!(ssh, command, ssh_exec_opts) }
    ensure
      STDERR.reopen(stderr_orig)
    end
  end

  def ssh_exec!(ssh, command, options)
    stdout_data = ''
    stderr_data = ''
    exit_code = nil
    #exit_signal = nil

    stdout_stream = create_stdout_stream
    stderr_stream = create_stderr_stream

    ssh.open_channel do |channel|
      if options[:request_pty]
        channel.request_pty do |ch, success|
          unless success
            raise "Couldn't obtain pty (ssh.channel.request_pty)"
          end
        end
      end

      channel.exec(command) do |ch, success|
        unless success
          raise "Couldn't execute command #{command.inspect} (ssh.channel.exec)"
        end

        channel.on_data do |ch, data|
          stdout_stream.push data
          stdout_data << data
        end

        channel.on_extended_data do |ch, type, data|
          stderr_stream.push data
          stderr_data << data
        end

        channel.on_request('exit-status') do |ch, data|
          exit_code = data.read_long
        end

        #channel.on_request('exit-signal') do |ch, data|
        #  exit_signal = data.read_long
        #end
      end
    end

    ssh.loop

    stdout_stream.close
    stderr_stream.close

    #[stdout_data, stderr_data, exit_code, exit_signal]
    [stdout_data, stderr_data, exit_code]
  end

  def run_shell_command(command, outputs)
    command = evaluate_command_template(command, outputs)

    stdout_data = ''
    stderr_data = ''
    exit_code = nil

    Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
      mutex = Mutex.new

      th_out = Thread.start do
        stdout_stream = create_stdout_stream

        stdout.each_line do |line|
          mutex.synchronize do
            stdout_stream.push line
          end

          stdout_data << line
        end

        stdout_stream.close
      end

      th_err = Thread.start do
        stderr_stream = create_stderr_stream

        stderr.each_line do |line|
          mutex.synchronize do
            stderr_stream.push line
          end
          stderr_data << line
        end

        stderr_stream.close
      end

      th_out.join
      th_err.join
      exit_code = wait_thr.value
    end

    #[stdout_data, stderr_data, exit_code, exit_signal]
    [stdout_data, stderr_data, exit_code]
  end

  def validate_command_template(name, command, outputs)
    command = command.undent if @command_options[:undent]
    trim_mode = @command_options[:trim_mode]
    expected_outputs = Set.new

    scope = Object.new
    scope.instance_variable_set(:@__expected_outputs__, expected_outputs)

    scope.instance_eval(<<-EOS)
      def Ref(name)
        $kumogata.options.parameters[name]
      end

      def Key(name)
        @__expected_outputs__ << name
      end

      ERB.new(#{command.inspect}, nil, #{trim_mode.inspect}).result(binding)
    EOS

    expected_outputs.each do |key|
      unless outputs.keys.include?(key)
        $stderr.puts("[WARN] Undefined output: #{name} => #{key.inspect}".yellow)
      end
    end
  end

  def evaluate_command_template(command, outputs)
    command = command.undent if @command_options[:undent]
    trim_mode = @command_options[:trim_mode]

    scope = Object.new
    scope.instance_variable_set(:@__outputs__, outputs)

    scope.instance_eval(<<-EOS)
      def Ref(name)
        $kumogata.options.parameters[name]
      end

      def Key(name)
        @__outputs__[name]
      end

      ERB.new(#{command.inspect}, nil, #{trim_mode.inspect}).result(binding)
    EOS
  end

  def print_command(name)
    puts <<-EOS

Command: #{name.intense_blue}
    EOS
  end

  def create_stdout_stream
    Kumogata::StringStream.new do |line|
      puts '1> '.intense_green + line
      $stdout.flush
    end
  end

  def create_stderr_stream
    Kumogata::StringStream.new do |line|
      puts '2> '.intense_red + line
      $stdout.flush
    end
  end

  def print_command_result(out, err, status) # XXX:
    status = status.to_i

    puts <<-EOS
Status: #{status.zero? ? status : status.to_s.red}
    EOS
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
