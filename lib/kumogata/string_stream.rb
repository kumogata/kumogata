class Kumogata::StringStream
  def initialize(&block)
    @buf = StringScanner.new('')
    @block = block

    @fiber = Fiber.new do
      self.run
    end

    # Step to `yield`
    @fiber.resume
  end

  def run
    loop do
      chunk = Fiber.yield
      break unless chunk

      @buf << chunk.to_s
      self.each_line
    end
  end

  def each_line
    while (line = @buf.scan_until(/(\r\n|\r|\n)/))
      @block.call(line.chomp)
    end
  end

  def push(chunk)
    @fiber.resume(chunk)
  end

  def close
    self.each_line
    @block.call(@buf.rest) if @buf.rest?
    @fiber.resume
  end
end
