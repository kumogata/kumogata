describe 'Kumogata::Client#create' do
  it 'create a stack from Ruby template' do
    template = <<-EOS
Resources do
  myEC2Instance do
    Type "AWS::EC2::Instance"
    Properties do
      ImageId "ami-XXXXXXXX"
      InstanceType "t1.micro"
    end
  end
end

Outputs do
  AZ do
    Value do
      Fn__GetAtt "myEC2Instance", "AvailabilityZone"
    end
  end
end
    EOS

    run_client(:create, :template => template) do |client, cf|
      json = eval_template(template, :update_deletion_policy => true).to_json

      output = make_double('output') do |obj|
        obj.should_receive(:key) { 'AZ' }
        obj.should_receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        obj.should_receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        obj.should_receive(:[]).with(:resource_status_reason) { nil }
        obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:status).and_return(
            'CREATE_COMPLETE', 'CREATE_COMPLETE',
            'DELETE_COMPLETE', 'DELETE_COMPLETE', 'DELETE_COMPLETE')
        obj.should_receive(:outputs) { [output] }
        obj.should_receive(:resource_summaries) { [resource_summary] }
        obj.should_receive(:delete)
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:create)
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {}) { stack }
        obj.should_receive(:[])
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX') { stack }
      end

      cf.should_receive(:stacks).twice { stacks }
    end
  end

  it 'create a stack from Ruby template with parameters' do
    template = <<-EOS
Parameters do
  InstanceType do
    Default "t1.micro"
    Description "Instance Type"
    Type "String"
  end
end

Resources do
  myEC2Instance do
    Type "AWS::EC2::Instance"
    Properties do
      ImageId "ami-XXXXXXXX"
      InstanceType { Ref "InstanceType" }
    end
  end
end

Outputs do
  AZ do
    Value do
      Fn__GetAtt "myEC2Instance", "AvailabilityZone"
    end
  end
end
    EOS

    run_client(:create, :template => template, :options => {:parameters => {'InstanceType'=>'m1.large'}}) do |client, cf|
      json = eval_template(template, :update_deletion_policy => true).to_json

      output = make_double('output') do |obj|
        obj.should_receive(:key) { 'AZ' }
        obj.should_receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        obj.should_receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        obj.should_receive(:[]).with(:resource_status_reason) { nil }
        obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:status).and_return(
            'CREATE_COMPLETE', 'CREATE_COMPLETE',
            'DELETE_COMPLETE', 'DELETE_COMPLETE', 'DELETE_COMPLETE')
        obj.should_receive(:outputs) { [output] }
        obj.should_receive(:resource_summaries) { [resource_summary] }
        obj.should_receive(:delete)
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:create)
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {:parameters=>{"InstanceType"=>"m1.large"}}) { stack }
        obj.should_receive(:[])
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX') { stack }
      end

      cf.should_receive(:stacks).twice { stacks }
    end
  end

  it 'create a stack from Ruby template with stack name' do
    template = <<-EOS
Resources do
  myEC2Instance do
    Type "AWS::EC2::Instance"
    Properties do
      ImageId "ami-XXXXXXXX"
      InstanceType "t1.micro"
    end
  end
end

Outputs do
  AZ do
    Value do
      Fn__GetAtt "myEC2Instance", "AvailabilityZone"
    end
  end
end
    EOS

    run_client(:create, :arguments => ['MyStack'], :template => template) do |client, cf|
      json = eval_template(template).to_json

      output = make_double('output') do |obj|
        obj.should_receive(:key) { 'AZ' }
        obj.should_receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        obj.should_receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        obj.should_receive(:[]).with(:resource_status_reason) { nil }
        obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:status).and_return(
            'CREATE_COMPLETE',
            'CREATE_COMPLETE')
        obj.should_receive(:outputs) { [output] }
        obj.should_receive(:resource_summaries) { [resource_summary] }
      end

      stacks = make_double('status') do |obj|
        obj.should_receive(:create)
           .with('MyStack', json, {}) { stack }
      end

      cf.should_receive(:stacks) { stacks }
    end
  end

  it 'create a stack from Ruby template with deletion policy retain' do
    template = <<-EOS
Resources do
  myEC2Instance do
    Type "AWS::EC2::Instance"
    Properties do
      ImageId "ami-XXXXXXXX"
      InstanceType "t1.micro"
    end
  end
end

Outputs do
  AZ do
    Value do
      Fn__GetAtt "myEC2Instance", "AvailabilityZone"
    end
  end
end
    EOS

    run_client(:create, :arguments => ['MyStack'], :template => template, :options => {:deletion_policy_retain => true}) do |client, cf|
      json = eval_template(template, :update_deletion_policy => true).to_json

      output = make_double('output') do |obj|
        obj.should_receive(:key) { 'AZ' }
        obj.should_receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        obj.should_receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        obj.should_receive(:[]).with(:resource_status_reason) { nil }
        obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:status).and_return(
            'CREATE_COMPLETE',
            'CREATE_COMPLETE')
        obj.should_receive(:outputs) { [output] }
        obj.should_receive(:resource_summaries) { [resource_summary] }
      end

      stacks = make_double('status') do |obj|
        obj.should_receive(:create)
           .with('MyStack', json, {}) { stack }
      end

      cf.should_receive(:stacks) { stacks }
    end
  end

  it 'create a stack from Ruby template with invalid stack name' do
    template = <<-EOS
Resources do
  myEC2Instance do
    Type "AWS::EC2::Instance"
    Properties do
      ImageId "ami-XXXXXXXX"
      InstanceType "t1.micro"
    end
  end
end

Outputs do
  AZ do
    Value do
      Fn__GetAtt "myEC2Instance", "AvailabilityZone"
    end
  end
end
    EOS

    expect {
      run_client(:create, :arguments => ['0MyStack'], :template => template)
    }.to raise_error("1 validation error detected: Value '0MyStack' at 'stackName' failed to satisfy constraint: Member must satisfy regular expression pattern: [a-zA-Z][-a-zA-Z0-9]*")
  end

  it 'create a stack from Ruby template with encrypted parameters' do
    template = <<-EOS
Parameters do
  InstanceType do
    Default "t1.micro"
    Description "Instance Type"
    Type "String"
  end
end

Resources do
  myEC2Instance do
    Type "AWS::EC2::Instance"
    Properties do
      ImageId "ami-XXXXXXXX"
      InstanceType { Ref "InstanceType" }
    end
  end
end

Outputs do
  AZ do
    Value do
      Fn__GetAtt "myEC2Instance", "AvailabilityZone"
    end
  end
end
    EOS

    run_client(:create, :template => template, :options => {:parameters => {'InstanceType'=>'m1.large'}, :encrypt_parameters => ['Password']}) do |client, cf|
      json = eval_template(template, :update_deletion_policy => true, :add_encryption_password => true).to_json

      output = make_double('output') do |obj|
        obj.should_receive(:key) { 'AZ' }
        obj.should_receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        obj.should_receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        obj.should_receive(:[]).with(:resource_status_reason) { nil }
        obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:status).and_return(
            'CREATE_COMPLETE', 'CREATE_COMPLETE',
            'DELETE_COMPLETE', 'DELETE_COMPLETE', 'DELETE_COMPLETE')
        obj.should_receive(:outputs) { [output] }
        obj.should_receive(:resource_summaries) { [resource_summary] }
        obj.should_receive(:delete)
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:create)
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {:parameters=>{"InstanceType"=>"m1.large", "EncryptionPassword"=>"KioqKioqKioqKioqKioqKg=="}}) { stack }
        obj.should_receive(:[])
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX') { stack }
      end

      cf.should_receive(:stacks).twice { stacks }
    end
  end
end
