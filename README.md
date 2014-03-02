# Kumogata

Kumogata is a tool for AWS CroudFormation.

[![Gem Version](https://badge.fury.io/rb/kumogata.png)](http://badge.fury.io/rb/kumogata)
[![Build Status](https://drone.io/github.com/winebarrel/kumogata/status.png)](https://drone.io/github.com/winebarrel/kumogata/latest)

It can define a template in Ruby DSL, such as:

```ruby
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
```

## Installation

    $ gem install kumogata

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( http://github.com/<my-github-username>/kumogata/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
