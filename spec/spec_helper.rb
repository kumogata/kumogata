if ENV['TRAVIS']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter "spec/"
  end
end

require 'kumogata'
require 'kumogata/argument_parser'
require 'tempfile'
require 'time'
require 'timecop'
require 'uuidtools'

Kumogata::ENCRYPTION_PASSWORD.replace('EncryptionPassword')

class UUIDTools::UUID
  def self.timestamp_create; 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'; end
end

class Kumogata::Utils
  def self.get_user_host
    'user-host'
  end
end

class Kumogata::Crypt
  def self.mkpasswd(n)
    '*' * n
  end
end

def tempfile(content, template_ext = nil)
  basename = "#{File.basename __FILE__}.#{$$}"
  basename = [basename, template_ext] if template_ext

  Tempfile.open(basename) do |f|
    f << content
    f.flush
    f.rewind
    yield(f)
  end
end

class Proc
  def to_s
    "<Proc Object>"
  end
end

def run_client(command, options = {})
  $stdout = open('/dev/null', 'w') unless ENV['DEBUG']

  kumogata_template = options[:template]
  kumogata_arguments = options[:arguments] || []
  kumogata_options = Kumogata::ArgumentParser::DEFAULT_OPTIONS.merge(options[:options] || {})
  kumogata_options[:result_log] = '/dev/null'
  kumogata_options[:command_result_log] = '/dev/null'
  template_ext = options[:template_ext] || '.rb'

  client = Kumogata::Client.new(kumogata_options)
  cloud_formation = client.instance_variable_get(:@cloud_formation)
  yield(client, cloud_formation) if block_given?

  if kumogata_template
    tempfile(kumogata_template, template_ext) do |f|
      kumogata_arguments.unshift(f.path)
      client.send(command, *kumogata_arguments)
    end
  else
    client.send(command, *kumogata_arguments)
  end
end

def eval_template(template, options = {})
  kumogata_options = Kumogata::ArgumentParser::DEFAULT_OPTIONS.merge(options[:options] || {})
  template_ext = options[:template_ext] || '.rb'

  template = tempfile(template, template_ext) do |f|
    Kumogata::Client.new(kumogata_options).send(:evaluate_template, f, f.path)
  end

  if options[:update_deletion_policy]
    update_deletion_policy(template)
  end

  if options[:add_encryption_password]
    add_encryption_password(template)
  end

  if options[:add_encryption_password_for_validation]
    add_encryption_password_for_validation(template)
  end

  return template
end

def update_deletion_policy(template)
  template['Resources'].each do |k, v|
    v['DeletionPolicy'] ||= 'Retain'
  end
end

def add_encryption_password(template)
  template['Parameters'] ||= {}

  template['Parameters'][Kumogata::ENCRYPTION_PASSWORD] = {
    'Type'   => 'String',
    'NoEcho' => 'true',
  }
end

def add_encryption_password_for_validation(template)
  template['Parameters'] ||= {}

  template['Parameters'][Kumogata::ENCRYPTION_PASSWORD] = {
    'Type' => 'String',
    'Default' => "(#{Kumogata::ENCRYPTION_PASSWORD})",
  }
end

def make_double(name)
  obj = double(name)
  yield(obj)
  return obj
end
