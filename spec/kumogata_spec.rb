describe Kumogata::Client do
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
      stacks = double('status')

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

      stacks = make_double('status') do |obj|
        obj.should_receive(:create)
           .with('kumogata-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {}) { stack }
        obj.should_receive(:[])
           .with('kumogata-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX') { stack }
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
      stacks = double('status')

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

  it 'validate Ruby template (without error)' do
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

    run_client(:validate, :template => template) do |client, cf|
      json = eval_template(template).to_json

      cf.should_receive(:validate_template).with(json) {
        {}
      }
    end
  end

  it 'validate Ruby template (with error)' do
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

#Outputs do
  AZ do
    Value do
      Fn__GetAtt "myEC2Instance", "AvailabilityZone"
    end
  end
#end
    EOS

    expect {
      run_client(:validate, :template => template) do |client, cf|
        json = eval_template(template).to_json

        cf.should_receive(:validate_template).with(json) {
          {
            :code => 'CODE',
            :message => 'MESSAGE'
          }
        }
      end
    }.to raise_error('CODE: MESSAGE')
  end

  it 'validate JSON template (without error)' do
    template = <<-EOS
{
  "Resources": {
    "myEC2Instance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": "ami-XXXXXXXX",
        "InstanceType": "t1.micro"
      }
    }
  },
  "AZ": {
    "Value": {
      "Fn::GetAtt": [
        "myEC2Instance",
        "AvailabilityZone"
      ]
    }
  }
}
    EOS

    run_client(:validate, :template => template, :template_ext => '.template') do |client, cf|
      json = JSON.parse(template).to_json

      cf.should_receive(:validate_template).with(json) {
        {}
      }
    end
  end

  it 'validate JSON template (with error)' do
    template = <<-EOS
{
  "Resources": {
    "myEC2Instance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": "ami-XXXXXXXX",
        "InstanceType": "t1.micro"
      }
    }
  },
  "AZ": {
    "Value": {
      "Fn::GetAtt": [
        "myEC2Instance",
        "AvailabilityZone"
      ]
    }
  }
}
    EOS

    expect {
      run_client(:validate, :template => template, :template_ext => '.template') do |client, cf|
        json = JSON.parse(template).to_json

        cf.should_receive(:validate_template).with(json) {
          {
            :code => 'CODE',
            :message => 'MESSAGE'
          }
        }
      end
    }.to raise_error('CODE: MESSAGE')
  end

  it 'convert Ruby template to JSON template' do
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

    json_template = run_client(:convert, :template => template)

    expect(json_template).to eq((<<-EOS).chomp)
{
  "Resources": {
    "myEC2Instance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": "ami-XXXXXXXX",
        "InstanceType": "t1.micro"
      }
    }
  },
  "Outputs": {
    "AZ": {
      "Value": {
        "Fn::GetAtt": [
          "myEC2Instance",
          "AvailabilityZone"
        ]
      }
    }
  }
}
    EOS
  end

  it 'convert Ruby template to JSON template' do
    template = <<-EOS
{
  "Resources": {
    "myEC2Instance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": "ami-07f68106",
        "InstanceType": "t1.micro"
      }
    }
  },
  "Outputs": {
    "AZ": {
      "Value": {
        "Fn::GetAtt": [
          "myEC2Instance",
          "AvailabilityZone"
        ]
      }
    }
  }
}
    EOS

    ruby_template = run_client(:convert, :template => template, :template_ext => '.template')

    expect(ruby_template).to eq((<<-EOS).chomp)
Resources do
  myEC2Instance do
    Type "AWS::EC2::Instance"
    Properties do
      ImageId "ami-07f68106"
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
  end
end
