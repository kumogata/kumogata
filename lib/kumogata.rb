module Kumogata; end
require 'kumogata/version'

require 'aws-sdk'
require 'base64'
require 'dslh'
require 'hashie'
require 'json'
require 'logger'
require 'open-uri'
require 'optparse'
require 'singleton'
require 'uuidtools'

require 'kumogata/argument_parser'
require 'kumogata/client'
require 'kumogata/ext/string_ext'
require 'kumogata/logger'
