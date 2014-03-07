class Kumogata::Utils
  class << self
    def camelize(str)
      str.to_s.split(/[-_]/).map {|i|
        i[0, 1].upcase + i[1..-1].downcase
      }.join
    end

    def get_user_host
      user = `whoami`.strip rescue ''
      host = `hostname`.strip rescue ''
      user_host = [user, host].select {|i| not i.empty? }.join('-')
      user_host.empty? ? nil : user_host
    end
  end # of class methods
end
