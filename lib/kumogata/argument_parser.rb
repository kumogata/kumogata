Version = Kumogata::VERSION
$kumogata = Hashie::Mash.new

class Kumogata::ArgumentParser
  DEFAULT_OPTIONS = {
    :delete_stack => true,
    :result_log => File.join(Dir.pwd, 'result.json'),
    :command_result_log => File.join(Dir.pwd, 'command_result.json'),
    :color => $stdout.tty?,
    :debug => false,
  }

  COMMANDS = {
    :create => {
      :description => 'Create resources as specified in the template',
      :arguments   => [:path_or_url, :stack_name?],
      :output      => false,
    },
    :validate => {
      :description => 'Validate a specified template',
      :arguments   => [:path_or_url],
      :output      => false,
    },
    :convert => {
      :description => 'Convert a template format',
      :arguments   => [:path_or_url],
    },
    :update => {
      :description => 'Update a stack as specified in the template',
      :arguments   => [:path_or_url, :stack_name],
      :output      => false,
    },
    :delete => {
      :description => 'Delete a specified stack',
      :arguments   => [:stack_name],
      :output      => false,
    },
    :list => {
      :description => 'List summary information for stacks',
      :arguments   => [:stack_name?],
    },
    :export => {
      :description => 'Export a template from a specified stack',
      :arguments   => [:stack_name],
    },
    :'show-events' => {
      :description => 'Show events for a specified stack',
      :arguments   => [:stack_name],
    },
    :'show-outputs' => {
      :description => 'Show outputs for a specified stack',
      :arguments   => [:stack_name],
    },
    :'show-resources' => {
      :description => 'Show resources for a specified stack',
      :arguments   => [:stack_name],
    },
    :diff => {
      :description => 'Compare templates logically (file, http://..., stack://...)',
      :arguments   => [:path_or_url1, :path_or_url2],
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

    if ENV['KUMOGATA_OPTIONS']
      ARGV.concat(scan_args(ENV['KUMOGATA_OPTIONS']))
    end

    ARGV.options do |opt|
      update_usage(opt)

      begin
        supported_formats = [:ruby, :json, :yaml, :js, :coffee, :json5]
        opt.on('-k', '--access-key ACCESS_KEY')                    {|v| options[:access_key_id]           = v     }
        opt.on('-s', '--secret-key SECRET_KEY')                    {|v| options[:secret_access_key]       = v     }
        opt.on('-r', '--region REGION')                            {|v| options[:region]                  = v     }
        opt.on(''  , '--config PATH')                              {|v| options[:config_path]             = v     }
        opt.on(''  , '--profile CONFIG_PROFILE')                   {|v| options[:config_profile]          = v     }
        opt.on(''  , '--format TMPLATE_FORMAT', supported_formats) {|v| options[:format]                  = v     }
        opt.on(''  , '--output-format FORMAT', supported_formats)  {|v| options[:output_format]           = v     }
        opt.on(''  , '--skip-replace-underscore')                  {    options[:skip_replace_underscore] = false }
        opt.on(''  , '--deletion-policy-retain')                   {    options[:deletion_policy_retain]  = true  }
        opt.on('-p', '--parameters KEY_VALUES', Array)             {|v| options[:parameters]              = v     }
        opt.on('-j', '--json-parameters JSON')                     {|v| options[:json_parameters]         = v     }
        opt.on('-e', '--encrypt-parameters KEYS', Array)           {|v| options[:encrypt_parameters]      = v     }
        opt.on('',   '--encryption-password PASS')                 {|v| options[:encryption_password]     = v     }
        opt.on('',   '--skip-send-password')                       {    options[:skip_send_password]      = true  }
        opt.on(''  , '--capabilities CAPABILITIES', Array)         {|v| options[:capabilities]            = v     }
        opt.on(''  , '--disable-rollback')                         {    options[:disable_rollback]        = true  }
        opt.on(''  , '--notify SNS_TOPICS', Array)                 {|v| options[:notify]                  = v     }
        opt.on(''  , '--timeout MINUTES', Integer)                 {|v| options[:timeout]                 = v     }
        opt.on(''  , '--result-log PATH')                          {|v| options[:result_log]              = v     }
        opt.on(''  , '--command-result-log PATH')                  {|v| options[:command]                 = v     }
        opt.on(''  , '--detach')                                   {    options[:detach]                  = true  }
        opt.on(''  , '--force')                                    {    options[:force]                   = true  }
        opt.on('-w', '--ignore-all-space')                         {    options[:ignore_all_space]        = true  }
        opt.on(''  , '--color')                                    {    options[:color]                   = true  }
        opt.on(''  , '--no-color')                                 {    options[:color]                   = false }
        opt.on(''  , '--debug')                                    {    options[:debug]                   = true  }
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

        update_parameters(options)
      rescue => e
        $stderr.puts("#{e.message}")
        raise e if options[:debug]
        exit 1
      end
    end

    output = COMMANDS[command].fetch(:output, true)
    command = command.to_s.gsub('-', '_').to_sym

    $kumogata.command = command
    $kumogata.arguments = arguments
    $kumogata.options = options
    options = $kumogata.options # Copy of the reference

    [command, arguments, options, output]
  end

  private

  def update_usage(opt)
    opt.banner = "Usage: kumogata <command> [args] [options]"
    opt.separator ''
    opt.separator 'Commands:'

    cmd_max = COMMANDS.keys.map {|i| i.to_s.length }.max

    cmd_arg_descs = COMMANDS.map {|command, attributes|
      description = attributes[:description]
      arguments = attributes[:arguments]

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

  def update_parameters(options)
    parameters = {}

    (options.parameters || []).each do |i|
      key, value = i.split('=', 2)
      parameters[key] = value
    end

    if options.json_parameters
      parameters.merge! JSON.parse(options.json_parameters)
    end

    options.parameters = parameters
  end

  def scan_args(str)
    args = []
    ss = StringScanner.new(str)
    buf = ''

    until ss.eos?
      if ss.scan(/\s+/)
        unless buf.empty?
          args << buf
          buf = ''
        end
      elsif (tok = ss.scan(/'[^']*'/))
        buf << tok.gsub(/'([^']*)'/) { $1 }
      elsif (tok = ss.scan(/"[^"]*"/))
        buf << tok.gsub(/"([^"]*)"/) { $1 }
      elsif (tok = ss.scan(/[^\s'"]+/))
        buf << tok
      else
        buf << ss.getch
      end
    end

    args << buf unless buf.empty?

    return args
  end
end
