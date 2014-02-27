class Kumogata::Client
  def initialize(options)
    @options = options
  end

  def create(path_or_url)
    p [:create, path_or_url]
  end
end
