CodeRay::Encoders::Terminal::TOKEN_COLORS[:constant] = "\e[1;34m"
CodeRay::Encoders::Terminal::TOKEN_COLORS[:float] = "\e[36m"
CodeRay::Encoders::Terminal::TOKEN_COLORS[:integer] = "\e[36m"
CodeRay::Encoders::Terminal::TOKEN_COLORS[:keyword] = "\e[1;31m"

CodeRay::Encoders::Terminal::TOKEN_COLORS[:key] = {
  :self => "\e[1;34m",
  :char => "\e[1;34m",
  :delimiter => "\e[1;34m",
}

CodeRay::Encoders::Terminal::TOKEN_COLORS[:string] = {
  :self => "\e[32m",
  :modifier => "\e[1;32m",
  :char => "\e[1;32m",
  :delimiter => "\e[1;32m",
  :escape => "\e[1;32m",
}
