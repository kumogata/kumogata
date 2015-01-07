describe 'Kumogata::Client#validate' do
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
      json = eval_template(template, :add_encryption_password_for_validation => true).to_json

      expect(cf).to receive(:validate_template).with(json) {
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
        json = eval_template(template, :add_encryption_password_for_validation => true).to_json

        expect(cf).to receive(:validate_template).with(json) {
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
      template = JSON.parse(template)
      add_encryption_password_for_validation(template)
      json = template.to_json

      expect(cf).to receive(:validate_template) {
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
        template = JSON.parse(template)
        add_encryption_password_for_validation(template)
        json = template.to_json

        expect(cf).to receive(:validate_template).with(json) {
          {
            :code => 'CODE',
            :message => 'MESSAGE'
          }
        }
      end
    }.to raise_error('CODE: MESSAGE')
  end

  it 'validate Ruby template (without verbose option)' do
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

    result = {"parameters"=>
               [{"no_echo"=>false,
                 "parameter_key"=>"SSHLocation",
                 "description"=>
                  "The IP address range that can be used to SSH to the EC2 instances",
                 "default_value"=>"0.0.0.0/0"},
                {"no_echo"=>false,
                 "parameter_key"=>"XXXXXXXXXXXXXXXX",
                 "default_value"=>"(XXXXXXXXXXXXXXXX)"},
                {"no_echo"=>false,
                 "parameter_key"=>"InstanceType",
                 "description"=>"WebServer EC2 instance type",
                 "default_value"=>"m1.small"},
                {"no_echo"=>false,
                 "parameter_key"=>"KeyName",
                 "description"=>
                  "Name of an existing EC2 KeyPair to enable SSH access to the instance"}],
              "capabilities"=>[],
              "description"=>"'test CloudFormation Template\n",
              "response_metadata"=>{"request_id"=>"XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"}}

    expect(Kumogata.logger).to receive(:info).with('Template validated successfully')
    expect(Kumogata.logger).to receive(:info).with(JSON.pretty_generate(result))

    run_client(:validate, :template => template, :options => {:verbose => true}) do |client, cf|
      json = eval_template(template, :add_encryption_password_for_validation => true).to_json
      expect(cf).to receive(:validate_template).with(json) { result }
    end
  end
end
