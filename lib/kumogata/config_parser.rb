class Kumogata::ConfigParser
  attr_reader :path

  def initialize(path = '~/.aws/config')
    self.path = path
    @profiles = {}
  end

  def path=(v)
    @path = Pathname.new(v).expand_path
  end

  def [](profile_name)
    @profiles[profile_name.to_s]
  end

  def parse!
    profile_name = nil

    @path.each_line do |line|
      line.strip!
      next if line.empty?

      if line =~ /\A\[(.+)\]\z/
        profile_name = $1.split.last
      elsif profile_name
        key, value = line.split('=', 2).map {|i| i.strip }
        @profiles[profile_name] ||= {}
        @profiles[profile_name][key] = value
      end
    end
  end
end
