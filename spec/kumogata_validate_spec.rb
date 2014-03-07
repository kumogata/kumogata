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
        json = eval_template(template, :add_encryption_password_for_validation => true).to_json

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
      template = JSON.parse(template)
      add_encryption_password_for_validation(template)
      json = template.to_json

      cf.should_receive(:validate_template) {
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

        cf.should_receive(:validate_template).with(json) {
          {
            :code => 'CODE',
            :message => 'MESSAGE'
          }
        }
      end
    }.to raise_error('CODE: MESSAGE')
  end
end
