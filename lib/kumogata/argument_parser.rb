Version = Kumogata::VERSION

class Kumogata::ArgumentParser
  DEFAULT_OPTIONS = {}

  COMMANDS = {
    :create => {
      :description => '(create description)',
      :arguments   => [:path_or_url]
    },
  }

  class << self
    def parse!
      self.new.parse!
    end
  end # of class methods

  def parse!
    command = nil
    arguments = nil
    options = {}

    ARGV.options do |opt|
      update_usage(opt)

      begin
        opt.on('-f', '--foo') {|v| options[:foo] = v }
        opt.on('-b', '--bar') {|v| options[:bar] = v }
        opt.parse!

        unless (command = ARGV.shift)
          puts opt.help
          exit 1
        end

        command = command.to_sym

        unless COMMANDS.has_key?(command)
          raise "Invalid command: #{command}"
        end

        arguments = ARGV.dup

        validate_arguments(command, arguments)
      rescue => e
        $stderr.puts e
        # XXX: Add debug mode
        exit 1
      end
    end

    {
      :command   => command,
      :arguments => arguments,
      :options   => DEFAULT_OPTIONS.merge(options),
    }
  end

  private

  def update_usage(opt)
    opt.banner = "Usage: kumogata <command> [args] [options]"
    opt.separator ''
    opt.separator 'Commands:'

    command_max_length = COMMANDS.keys.map(&:length).max

    opt.separator(COMMANDS.map {|command, attributes|
      description = attributes[:description]
      '  %-*s  %-s' % [command_max_length, command, description]
    }.join("\n"))

    opt.separator ''
    opt.separator 'Options:'
  end

  def validate_arguments(command, arguments)
    expected = COMMANDS[command][:arguments] || []

    min = expected.count {|i| i.to_s !~ /\?\Z/ }
    max = expected.length

    if arguments.length < min or max < arguments.length
      expected_arguments = expected.map {|i| i.to_s.sub(/(.+)\?\Z/) { "[#{$1}]" }.upcase }.join(' ')
      raise "Usage: kumogata #{command} #{expected_arguments} [options]"
    end
  end
end
