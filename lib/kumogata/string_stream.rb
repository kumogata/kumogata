class Kumogata::StringStream
  def initialize(&block)
    @buf = StringScanner.new('')
    @block = block

    @fiber = Fiber.new do
      self.each_line
    end

    # Step to `yield`
    @fiber.resume
  end

  def each_line
    loop do
      chunk = Fiber.yield
      break unless chunk

      @buf << chunk.to_s

      line = @buf.scan_until(/(\r\n|\r|\n)/)
      @block.call(line.chomp) if line
    end
  end

  def push(chunk)
    @fiber.resume(chunk)
  end

  def close
    @block.call(@buf.rest) if @buf.rest?
    @fiber.resume
  end
end
