module JSON
  class << self
    alias pretty_generate_orig pretty_generate

    def pretty_generate(object, options = nil)
      begin
        pretty_generate_orig(object, options)
      rescue JSON::NestingError => e
        e.message << ': Undefined function may have been referenced [e.g. _user_data()/_join()]'
        raise e
      end
    end
  end
end
