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

```
Usage: kumogata <command> [args] [options]

Commands:
  create   PATH_OR_URL [STACK_NAME]  Creates a stack as specified in the template
  validate PATH_OR_URL               Validates a specified template
  convert  PATH_OR_URL               Convert a template format
  update   PATH_OR_URL STACK_NAME    Updates a stack as specified in the template
  delete   STACK_NAME                Deletes a specified stack
  list     [STACK_NAME]              List summary information for stacks

Options:
    -k, --access-key ACCESS_KEY
    -s, --secret-key SECRET_KEY
    -r, --region REGION
        --skip-replace-underscore
        --skip-delete-stack
    -p, --parameters KEY_VALUES
        --capabilities CAPABILITIES
        --disable-rollback
        --notify SNS_TOPICS
        --timeout MINUTES
        --result-log PATH
        --force
        --no-color
        --debug
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/kumogata/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
