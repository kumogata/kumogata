Version = Kumogata::VERSION

class Kumogata::ArgumentParser
  DEFAULT_OPTIONS = {
    :replace_underscore => true,
    :delete_stack => true,
    :result_log => File.join(Dir.pwd, 'result.json'),
    :color => true,
    :debug => false,
  }

  COMMANDS = {
    :create => {
      :description => 'Creates a stack as specified in the template',
      :arguments   => [:path_or_url, :stack_name?]
    },
    :validate => {
      :description => 'Validates a specified template',
      :arguments   => [:path_or_url]
    },
    :convert => {
      :description => '(convert description)',
      :arguments   => [:path_or_url]
    },
    :update => {
      :description => '(update description)',
      :arguments   => [:path_or_url, :stack_name]
    },
    :delete => {
      :description => '(delete description)',
      :arguments   => [:stack_name]
    },
    :list => {
      :description => '(list description)',
      :arguments   => [:stack_name?]
    },
  }

  class << self
    def parse!(&block)
      self.new.parse!(&block)
    end
  end # of class methods

  def parse!
    command = nil
    arguments = nil
    options = {}

    ARGV.options do |opt|
      update_usage(opt)

      begin
        opt.on('-k', '--access-key ACCESS_KEY')            {|v| options[:access_key_id]      = v     }
        opt.on('-s', '--secret-key SECRET_KEY')            {|v| options[:secret_access_key]  = v     }
        opt.on('-r', '--region REGION')                    {|v| options[:region]             = v     }
        opt.on(''  , '--skip-replace-underscore')          {    options[:replace_underscore] = false }
        opt.on(''  , '--skip-delete-stack')                {    options[:delete_stack]       = false }
        opt.on('-p', '--parameters KEY_VALUES', Array)     {|v| options[:parameters]         = v     }
        opt.on(''  , '--capabilities CAPABILITIES', Array) {|v| options[:capabilities]       = v     }
        opt.on(''  , '--disable-rollback')                 {    options[:disable_rollback]   = true  }
        opt.on(''  , '--notify SNS_TOPICS', Array)         {|v| options[:notify]             = v     }
        opt.on(''  , '--timeout MINUTES', Integer)         {|v| options[:timeout]            = v     }
        opt.on(''  , '--result-log PATH')                  {|v| options[:result_log]         = v     }
        opt.on(''  , '--force')                            {    options[:force]              = true  }
        opt.on(''  , '--no-color')                         {    options[:color]              = false }
        opt.on(''  , '--debug')                            {    options[:debug]              = true  }
        opt.parse!

        unless (command = ARGV.shift)
          puts opt.help
          exit 1
        end

        command = command.to_sym

        unless COMMANDS.has_key?(command)
          raise "Unknown command: #{command}"
        end

        arguments = ARGV.dup
        validate_arguments(command, arguments)

        options = DEFAULT_OPTIONS.merge(options)
        options = Hashie::Mash.new(options)

        if block_given?
          yield(opt, command, arguments, options)
        end
      rescue => e
        $stderr.puts("#{e.message}")
        exit 1
      end
    end

    [command, arguments, options]
  end

  private

  def update_usage(opt)
    opt.banner = "Usage: kumogata <command> [args] [options]"
    opt.separator ''
    opt.separator 'Commands:'

    cmd_max = COMMANDS.keys.map {|i| i.to_s.length }.max

    cmd_arg_descs = COMMANDS.map {|command, attributes|
      arguments = attributes[:arguments]
      description = attributes[:description]

      [
        '%-*s %s' % [cmd_max, command, arguments_to_message(arguments)],
        description,
      ]
    }

    cmd_arg_max = cmd_arg_descs.map {|i| i[0].length }.max

    opt.separator(cmd_arg_descs.map {|cmd_arg, desc|
      '  %-*s  %-s' % [cmd_arg_max, cmd_arg, desc]
    }.join("\n"))

    opt.separator ''
    opt.separator 'Options:'
  end

  def validate_arguments(command, arguments)
    expected = COMMANDS[command][:arguments] || []

    min = expected.count {|i| i.to_s !~ /\?\Z/ }
    max = expected.length

    if arguments.length < min or max < arguments.length
      raise "Usage: kumogata #{command} #{arguments_to_message(expected)} [options]"
    end
  end

  def arguments_to_message(arguments)
    arguments.map {|i| i.to_s.sub(/(.+)\?\Z/) { "[#{$1}]" }.upcase }.join(' ')
  end
end
