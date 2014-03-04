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

  def encode64
    Base64.encode64(self).delete("\n")
  end

  def undent
    min_space_num = self.split("\n").delete_if{|s| s=~ /^\s*$/ }.map{|s| s[/^\s+/].length }.min
    gsub(/^[ \t]{,#{min_space_num}}/, '')
  end
end
