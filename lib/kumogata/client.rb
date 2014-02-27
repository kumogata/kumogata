class Kumogata::Client
  def initialize(options)
    @options = options
    @cloud_formation = AWS::CloudFormation.new
  end

  def create(path_or_url)
    template = open(path_or_url) do |f|
      evaluate_template(f)
    end

    if @options.delete_stack?
      template['Resources'].each do |k, v|
        v['DeletionPolicy'] = 'Retain'
      end
    end

    create_stack(template)
  end

  private

  def evaluate_template(template)
    key_converter = proc do |key|
      key = key.to_s
      key.gsub!('__', '::') if @options.replace_underscore?
      key
    end

    value_converter = proc {|v| v.to_s }

    Dslh.eval(template.read, {
      :key_conv   => key_converter,
      :value_conv => value_converter,
      :filename   => template.path
    })
  end

  def create_stack(template)
    stack_name = 'kumogata-' + UUIDTools::UUID.timestamp_create
    stack = @cloud_formation.stacks.create(stack_name, template.to_json)

    print 'Creating'

    while stack.status == 'CREATE_IN_PROGRESS'
      print '.'
      sleep 1
    end

    status = stack.status
    completed = (status == 'CREATE_COMPLETE')

    if @options.delete_stack and completed
      stack.delete
    end

    status_message = status.split('_').last.camelcase
    puts status_message.send(completed ? :green : :red)
  end
end
