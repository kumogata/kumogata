class V8::Object
  def to_hash
    to_hash0(self)
  end

  def to_hash0(obj)
    case obj
    when V8::Array
      obj.map {|v| to_hash0(v) }
    when V8::Object
      h = {}
      obj.each do |k, v|
        h[to_hash0(k)] = to_hash0(v)
      end
      h
    else
      obj
    end
  end
end
