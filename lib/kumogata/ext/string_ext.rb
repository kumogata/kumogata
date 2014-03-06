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

  def colorize_as(lang)
    if @@colorize
      CodeRay.scan(self, lang).terminal
    else
      self
    end
  end

  def encode64
    Base64.encode64(self).delete("\n")
  end

  def undent
    min_space_num = self.split("\n").delete_if {|s| s =~ /^\s*$/ }.map {|s| (s[/^\s+/] || '').length }.min

    if min_space_num and min_space_num > 0
      gsub(/^[ \t]{,#{min_space_num}}/, '')
    else
      self
    end
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
        value = {'Fn::Base64' => @__value_conv__[value]}

        case @__functions__
        when Array
          @__functions__ << value
        when Hash
          @__functions__.update(value)
        end

        #{null.inspect}
      end

      def Fn__FindInMap(map_name, top_level_key, second_level_key)
        value = {'Fn::FindInMap' => [
          map_name, top_level_key, second_level_key].map(&@__value_conv__)}

        case @__functions__
        when Array
          @__functions__ << value
        when Hash
          @__functions__.update(value)
        end

        #{null.inspect}
      end

      def Fn__GetAtt(logical_name, attr_name)
        value = {'Fn::GetAtt' => [
          logical_name, attr_name].map(&@__value_conv__)}

        case @__functions__
        when Array
          @__functions__ << value
        when Hash
          @__functions__.update(value)
        end

        #{null.inspect}
      end

      def Fn__GetAZs(region)
        value = {'Fn::GetAZs' => @__value_conv__[region]}

        case @__functions__
        when Array
          @__functions__ << value
        when Hash
          @__functions__.update(value)
        end

        #{null.inspect}
      end

      def Ref(value)
        value = {'Ref' => value}

        case @__functions__
        when Array
          @__functions__ << value
        when Hash
          @__functions__.update(value)
        end

        #{null.inspect}
      end

      def _(&block)
        __functions__orig = @__functions__
        @__functions__ = {}
        block.call if block
        value = @__functions__
        @__functions__ = __functions__orig
        return value
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
