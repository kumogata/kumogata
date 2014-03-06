module Kumogata; end
require 'kumogata/version'

require 'aws-sdk'
require 'base64'
require 'coderay'
require 'diffy'
require 'dslh'
require 'hashie'
require 'highline/import'
require 'json'
require 'logger'
require 'open-uri'
require 'optparse'
require 'singleton'
require 'stringio'
require 'uuidtools'

require 'kumogata/argument_parser'
require 'kumogata/client'
require 'kumogata/ext/json_ext'
require 'kumogata/ext/string_ext'
require 'kumogata/logger'

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

CodeRay::Encoders::Terminal::TOKEN_COLORS[:keyword] = "\e[31m"
