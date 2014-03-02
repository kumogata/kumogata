# Kumogata

Kumogata is a tool for AWS CroudFormation.

[![Gem Version](https://badge.fury.io/rb/kumogata.png?201403022336)](http://badge.fury.io/rb/kumogata)
[![Build Status](https://drone.io/github.com/winebarrel/kumogata/status.png?201403022336)](https://drone.io/github.com/winebarrel/kumogata/latest)

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
      KeyName "your_key_name"

      UserData _user_data(<<-EOS)
        #!/bin/bash
        yum install -y httpd
        service httpd start
      EOS
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
  create   PATH_OR_URL [STACK_NAME]  Create resources as specified in the template
  validate PATH_OR_URL               Validate a specified template
  convert  PATH_OR_URL               Convert a template format
  update   PATH_OR_URL STACK_NAME    Update a stack as specified in the template
  delete   STACK_NAME                Delete a specified stack
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

### Create resources

    $ kumogata create template.rb

If you want to save the stack, please specify the stack name:

    $ kumogata create template.rb any_stack_name

If you want to pass parameters, please use `-p` option:

    $ kumogata create template.rb -p "InstanceType=m1.large,KeyName=any_other_key"


**Notice**

**The stack will be delete if you do not specify the stack name explicitly.**
(And only the resources will remain)

I think the stack that manage resources is not required in many case...

### Convert JSON to Ruby

JSON template can be converted to Ruby template.

    $ kumogata convert https://s3.amazonaws.com/cloudformation-templates-us-east-1/Drupal_Single_Instance.template

* Data that cannot be converted will be converted to Array and Hash
* `::` is converted to `__`
  * `Fn::GetAtt` => `Fn__GetAtt`
* `_{ ... }` is convered to Hash
  * `SecurityGroups [_{Ref "WebServerSecurityGroup"}]` => `{"SecurityGroups": [{"Ref": "WebServerSecurityGroup"}]}`
* `_user_data()` creates Base64-encoded UserData
* `_path()` creates Hash that has a key of path
  * `_path("/etc/passwd-s3fs") { content "..." }` => `{"/etc/passwd-s3fs": {"content": "..."}}`

## Demo

* Create resources
  * https://asciinema.org/a/7979
* Convert a template
  * https://asciinema.org/a/7980

## Contributing

1. Fork it ( http://github.com/winebarrel/kumogata/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
