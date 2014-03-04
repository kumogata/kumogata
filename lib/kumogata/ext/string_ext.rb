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

  def fn_join(options = {})
    options = {
      :undent    => true,
      :trim_mode => nil,
    }.merge(options)

    data = self.dup
    data = data.undent if options[:undent]
    trim_mode = options[:trim_mode]
    null = "\0"

    data = Object.new.instance_eval(<<-EOS)
      @__functions__ = []

      @__value_conv__ = proc do |v|
        case v
        when Array, Hash
          v
        else
          v.to_s
        end
      end

      def Fn__Base64(value)
        @__functions__ << {'Fn::Base64' => @__value_conv__[value]}
        #{null.inspect}
      end

      def Fn__FindInMap(map_name, top_level_key, second_level_key)
        @__functions__ << {'Fn::FindInMap' => [
          map_name, top_level_key, second_level_key].map(&@__value_conv__)}
        #{null.inspect}
      end

      def Fn__GetAtt(logical_name, attr_name)
        @__functions__ << {'Fn::GetAtt' => [
          logical_name, attr_name].map(&@__value_conv__)}
        #{null.inspect}
      end

      def Fn__GetAZs(region)
        @__functions__ << {'Fn::GetAZs' => @__value_conv__[region]}
        #{null.inspect}
      end

      def Ref(value)
        @__functions__ << {'Ref' => value}
        #{null.inspect}
      end

      ERB.new(#{data.inspect}, nil, #{trim_mode.inspect}).result(binding).split(#{null.inspect}).zip(@__functions__)
    EOS

    data = data.flatten.select {|i| not i.nil? }.map {|i|
      if i.kind_of?(String)
        StringIO.new(i).to_a
      else
        i
      end
    }.flatten

    return {
      'Fn::Join' => ['', data]
    }
  end
end
