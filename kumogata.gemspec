# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kumogata/version'

Gem::Specification.new do |spec|
  spec.name          = 'kumogata'
  spec.version       = Kumogata::VERSION
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sgwr_dts@yahoo.co.jp']
  spec.summary       = %q{A tool for AWS CloudFormation.}
  spec.description   = %q{A tool for AWS CloudFormation. It can define a template in Ruby DSL.}
  spec.homepage      = 'http://kumogata.codenize.tools/'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk-v1'
  spec.add_dependency 'coderay'
  spec.add_dependency 'coffee-script'
  spec.add_dependency 'diffy'
  spec.add_dependency 'dslh', '>= 0.2.7'
  spec.add_dependency 'hashie'
  spec.add_dependency 'highline'
  spec.add_dependency 'json'
  spec.add_dependency 'json5'
  spec.add_dependency 'net-ssh'
  spec.add_dependency 'retryable', '~> 2.0.0'
  spec.add_dependency 'term-ansicolor'
  spec.add_dependency 'therubyracer'
  spec.add_dependency 'uuidtools'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'timecop'
end
