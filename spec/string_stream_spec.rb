describe Kumogata::StringStream do
  it 'pass the line ("\n")' do
    lines = []

    sstream = Kumogata::StringStream.new do |line|
      lines << line
    end

    sstream.push("chunk1")
    sstream.push("chunk2\n")
    sstream.push("chunk3")
    sstream.push("chunk4")
    sstream.push("chunk5\n")
    sstream.push("\n")
    sstream.push("\n")
    sstream.push("chunk6")
    sstream.push("chunk7")
    sstream.close

    expect(lines).to eq([
      "chunk1chunk2",
      "chunk3chunk4chunk5",
      "",
      "",
      "chunk6chunk7",
    ])
  end

  it 'pass the line ("\r")' do
    lines = []

    sstream = Kumogata::StringStream.new do |line|
      lines << line
    end

    sstream.push("chunk1")
    sstream.push("chunk2\r")
    sstream.push("chunk3")
    sstream.push("chunk4")
    sstream.push("chunk5\r")
    sstream.push("\r")
    sstream.push("\r")
    sstream.push("chunk6")
    sstream.push("chunk7")
    sstream.close

    expect(lines).to eq([
      "chunk1chunk2",
      "chunk3chunk4chunk5",
      "",
      "",
      "chunk6chunk7",
    ])
  end

  it 'pass the line ("\r\n")' do
    lines = []

    sstream = Kumogata::StringStream.new do |line|
      lines << line
    end

    sstream.push("chunk1")
    sstream.push("chunk2\r\n")
    sstream.push("chunk3")
    sstream.push("chunk4")
    sstream.push("chunk5\r\n")
    sstream.push("\r\n")
    sstream.push("\r\n")
    sstream.push("chunk6")
    sstream.push("chunk7")
    sstream.close

    expect(lines).to eq([
      "chunk1chunk2",
      "chunk3chunk4chunk5",
      "",
      "",
      "chunk6chunk7",
    ])
  end

  it 'pass the line ("\n" / "\r" / "\r\n")' do
    lines = []

    sstream = Kumogata::StringStream.new do |line|
      lines << line
    end

    sstream.push("chunk1")
    sstream.push("chunk2\n")
    sstream.push("chunk3")
    sstream.push("chunk4")
    sstream.push("chunk5\r")
    sstream.push("\r\n")
    sstream.push("\n")
    sstream.push("chunk6")
    sstream.push("chunk7")
    sstream.push("chunk1")
    sstream.push("chunk2\r")
    sstream.push("chunk3")
    sstream.push("chunk4")
    sstream.push("chunk5\n\r")
    sstream.push("\n")
    sstream.push("\r")
    sstream.push("chunk6")
    sstream.push("chunk7")
    sstream.close

    expect(lines).to eq([
      "chunk1chunk2",
      "chunk3chunk4chunk5",
      "",
      "",
      "chunk6chunk7chunk1chunk2",
      "chunk3chunk4chunk5",
      "",
      "",
      "",
      "chunk6chunk7",
    ])
  end
end
