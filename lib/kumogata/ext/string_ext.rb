require 'term/ansicolor'

class String
  @@colorize = false

  class << self
    def colorize=(value)
      @@colorize = value
    end

    def colorize
      @@colorize
    end
  end # of class methods

  Term::ANSIColor::Attribute.named_attributes.map do |attribute|
    class_eval(<<-EOS, __FILE__, __LINE__ + 1)
      def #{attribute.name}
        if @@colorize
          Term::ANSIColor.send(#{attribute.name.inspect}, self)
        else
          self
        end
      end
    EOS
  end

  def camelcase
    self[0, 1].upcase + self[1..-1].downcase
  end

  def encode64
    Base64.encode64(self).delete("\n")
  end

  def strip_lines
    self.strip.split("\n").map {|i| i.strip }.join("\n")
  end
end
