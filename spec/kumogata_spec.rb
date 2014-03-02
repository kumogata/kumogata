describe Kumogata::Client do
  it 'validate Ruby template (without error)' do
    template = <<-EOS
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

    run_client(:validate, :template => template) do |client, cf|
      json = eval_template(template).to_json

      cf.should_receive(:validate_template).with(json) {
        {}
      }
    end
  end

  it 'convert Ruby template to JSON template' do
    template = <<-EOS
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

    json_template = run_client(:convert, :template => template)

    expect(json_template).to eq((<<-EOS).chomp)
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
