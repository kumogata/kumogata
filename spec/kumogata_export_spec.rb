describe 'Kumogata::Client#export' do
  it 'export a template' do
    json = <<-EOS
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

    template = run_client(:export, :arguments => ['MyStack']) do |client, cf|
      stack = make_double('stack') do |obj|
        obj.should_receive(:status) { 'CREATE_COMPLETE' }
        obj.should_receive(:template) { json }
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[]).with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }
    end

    expect(template).to eq((<<-EOS).chomp)
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
  end

  it 'export a JSON template' do
    json = <<-EOS
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

    template = run_client(:export, :arguments => ['MyStack'], :options => {:format => :json}) do |client, cf|
      stack = make_double('stack') do |obj|
        obj.should_receive(:status) { 'CREATE_COMPLETE' }
        obj.should_receive(:template) { json }
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[]).with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }
    end

    expect(template).to eq((<<-EOS).chomp)
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
end
