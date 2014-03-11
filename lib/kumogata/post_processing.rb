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
      validate_timing(name, timing)

      command = attrs['command']
      next unless command

      @commands[name] = {
        :after   => timing,
        :command => command,
      }

      if (ssh = attrs['ssh'])
        validate_ssh(name, ssh)
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

    save_command_results(results) unless results.empty?
  end

  private

  def validate_timing(name, timing)
    timing.each do |t|
      unless TRIGGER_TIMING.include?(t)
        raise "Unknown post processing timing #{timing.inspect} in #{name}"
      end
    end
  end

  def validate_ssh(name, ssh)
    host, user, options = ssh.values_at('host', 'user', 'options')

    unless host and user
      raise "`host` and `user` is required for post processing ssh in #{name}"
    end

    if host.kind_of?(Hash)
      if host.keys != ['Key']
        raise "Invalid post processing ssh host #{host.inspect} in #{name}"
      end

      host_key, host_value = host.first
      ssh['host'] = "<%= #{host_key} #{host_value.to_s.inspect} %>"
    else
      ssh['host'] = host.to_s
    end

    if user.kind_of?(Hash)
      if user.keys != ['Key']
        raise "Invalid post processing ssh user #{user.inspect} in #{name}"
      end

      user_key, user_value = user.first
      ssh['user'] = "<%= #{user_key} #{user_value.to_s.inspect} %>"
    else
      ssh['user'] = user.to_s
    end

    if options and not options.kind_of?(Hash)
      raise "Invalid post processing ssh options #{user.inspect} in #{name}"
    end
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

    begin
      Net::SSH.start(*args) {|ssh| ssh_exec!(ssh, command) }
    rescue Net::SSH::HostKeyMismatch => e
      e.remember_host!
      retry
    end
  end

  def ssh_exec!(ssh, command)
    stdout_data = ''
    stderr_data = ''
    exit_code = nil
    #exit_signal = nil

    ssh.open_channel do |channel|
      channel.exec(command) do |ch, success|
        unless success
          raise "Couldn't execute command #{command.inspect} (ssh.channel.exec)"
        end

        channel.on_data do |ch, data|
          stdout_data << data
        end

        channel.on_extended_data do |ch, type, data|
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

    #[stdout_data, stderr_data, exit_code, exit_signal]
    [stdout_data, stderr_data, exit_code]
  end

  def run_shell_command(command, outputs)
    command = evaluate_command_template(command, outputs)
    Open3.capture3(command)
  end

  def evaluate_command_template(command, outputs)
    command = command.undent if @command_options[:undent]
    trim_mode = @command_options[:trim_mode]

    scope = Object.new
    scope.instance_variable_set(:@__outputs__, outputs)

    scope.instance_eval(<<-EOS)
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

  def print_command_result(out, err, status)
    status = status.to_i
    dspout = (out || '').lines.map {|i| "1> ".intense_green + i }.join.chomp
    dsperr = (err || '').lines.map {|i| "2> ".intense_red + i }.join.chomp

    puts <<-EOS
Status: #{status.zero? ? status : status.to_s.red}#{
  dspout.empty? ? '' : ("\n---\n" + dspout)
}#{
  dsperr.empty? ? '' : ("\n---\n" + dsperr)
}
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
