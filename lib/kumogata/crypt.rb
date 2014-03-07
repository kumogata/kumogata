class Kumogata::Crypt
  ALGORITHM = 'aes256'
  PASSWORD_CHARS = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ123456789_*;:@{}()[]#$%&=-'

  class << self
    def encrypt(pass, str)
      IO.popen("openssl enc -e -#{ALGORITHM} -pass pass:#{enquote(pass)}", "r+") {|io|
        io.print str
        io.close_write
        io.read
      }.encode64
    end

    def decrypt(pass, str)
      IO.popen("openssl enc -d -#{ALGORITHM} -pass pass:#{enquote(pass)}", "r+") {|io|
        io.print Base64.decode64(str)
        io.close_write
        io.read
      }
    end

    def mkpasswd(n)
      PASSWORD_CHARS.split(//).sample(n).join
    end

    private

    def enquote(str)
      "'" + str.gsub("'", %!'"'"'!) + "'"
    end
  end # of class methods
end
