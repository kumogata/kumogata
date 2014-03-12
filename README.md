# Kumogata

![Stack is not required!](http://serif.hatelabo.jp/images/cache/a69b56ca6985b6ee7e605a102445953f355f54f5/62192c286da4377e608f3f5a5200f1bec272a92e.gif)


Kumogata is a tool for [AWS CloudFormation](https://aws.amazon.com/cloudformation/).

[![Gem Version](https://badge.fury.io/rb/kumogata.png?201403130002)](http://badge.fury.io/rb/kumogata)
[![Build Status](https://drone.io/github.com/winebarrel/kumogata/status.png?201403130002)](https://drone.io/github.com/winebarrel/kumogata/latest)

It can define a template in Ruby DSL, such as:

```ruby
AWSTemplateFormatVersion "2010-09-09"

Description (<<-EOS).undent
  Kumogata Sample Template
  You can use Here document!
EOS

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

      UserData (<<-EOS).undent.encode64
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

Ruby template structure is almost the same as [JSON template](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-structure.html).

## Installation

    $ gem install kumogata

## Usage

```
Usage: kumogata <command> [args] [options]

Commands:
  create         PATH_OR_URL [STACK_NAME]   Create resources as specified in the template
  validate       PATH_OR_URL                Validate a specified template
  convert        PATH_OR_URL                Convert a template format
  update         PATH_OR_URL STACK_NAME     Update a stack as specified in the template
  delete         STACK_NAME                 Delete a specified stack
  list           [STACK_NAME]               List summary information for stacks
  export         STACK_NAME                 Export a template from a specified stack
  show-events    STACK_NAME                 Show events for a specified stack
  show-outputs   STACK_NAME                 Show outputs for a specified stack
  show-resources STACK_NAME                 Show resources for a specified stack
  diff           PATH_OR_URL1 PATH_OR_URL2  Compare templates logically

Options:
    -k, --access-key ACCESS_KEY
    -s, --secret-key SECRET_KEY
    -r, --region REGION
        --format TMPLATE_FORMAT
        --skip-replace-underscore
        --deletion-policy-retain
    -p, --parameters KEY_VALUES
    -e, --encrypt-parameters KEYS
        --encryption-password PASS
        --skip-send-password
        --capabilities CAPABILITIES
        --disable-rollback
        --notify SNS_TOPICS
        --timeout MINUTES
        --result-log PATH
        --command-result-log PATH
        --force
    -w, --ignore-all-space
        --no-color
        --debug
```

### KUMOGATA_OPTIONS

`KUMOGATA_OPTIONS` variable specifies default options.

e.g. `KUMOGATA_OPTIONS='-e Password'`

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
* `_path()` creates Hash that has a key of path
  * `_path("/etc/passwd-s3fs") { content "..." }` => `{"/etc/passwd-s3fs": {"content": "..."}}`
* ~~_user_data() creates Base64-encoded UserData~~
  * `_user_data()` has been removed
* `_join()` has been removed

### String#fn_joine()

Ruby templates will be converted as follows by `String#fn_join()`:

```ruby
UserData do
  Fn__Base64 (<<-EOS).fn_join
    #!/bin/bash
    /opt/aws/bin/cfn-init -s <%= Ref "AWS::StackName" %> -r myEC2Instance --region <%= Ref "AWS::Region" %>
  EOS
end
```

```javascript
"UserData": {
  "Fn::Base64": {
    "Fn::Join": [
      "",
      [
        "#!/bin/bash\n",
        "/opt/aws/bin/cfn-init -s ",
        {
          "Ref": "AWS::StackName"
        },
        " -r myEC2Instance --region ",
        {
          "Ref": "AWS::Region"
        },
        "\n"
      ]
    ]
  }
}
```

### Split a template file

* template.rb

```ruby
Resources do
  _include 'template2.rb'
end
```

* template2.rb

```ruby
myEC2Instance do
  Type "AWS::EC2::Instance"
  Properties do
    ImageId "ami-XXXXXXXX"
    InstanceType { Ref "InstanceType" }
    KeyName "your_key_name"
  end
end
```

* Converted JSON template

```javascript
{
  "Resources": {
    "myEC2Instance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": "ami-XXXXXXXX",
        "InstanceType": {
          "Ref": "InstanceType"
        },
        "KeyName": "your_key_name"
      }
    }
  }
}
```

### Encrypt parameters

* Command line

```
$ kumogata create template.rb -e 'Password1,Password2' -p 'Param1=xxx,Param2=xxx,Password1=xxx,Password2=xxx'
```

* Template

```ruby
Parameters do
  Param1 { Type "String" }
  Param2 { Type "String" }
  Password1 { Type "String"; NoEcho true }
  Password2 { Type "String"; NoEcho true }
end # Parameters

Resources do
  myEC2Instance do
    Type "AWS::EC2::Instance"

    Properties do
      ImageId "ami-XXXXXXXX"

      UserData do
        Fn__Base64 (<<-EOS).fn_join
          #!/bin/bash
          /opt/aws/bin/cfn-init -s <%= Ref "AWS::StackName" %> -r myEC2Instance --region <%= Ref "AWS::Region" %>
        EOS
      end
    end

    Metadata do
      AWS__CloudFormation__Init do
        config do
          commands do
            any_command do
              command (<<-EOS).fn_join
                ENCRYPTION_PASSWORD="`echo '<%= Ref Kumogata::ENCRYPTION_PASSWORD %>' | base64 -d`"

                # Decrypt Password1
                echo '<%= Ref "Password1" %>' | base64 -d | openssl enc -d -aes256 -pass pass:"$ENCRYPTION_PASSWORD" > password1

                # Decrypt Password2
                echo '<%= Ref "Password2" %>' | base64 -d | openssl enc -d -aes256 -pass pass:"$ENCRYPTION_PASSWORD" > password2
              EOS
            end
          end
        end
      end
    end
  end # myEC2Instance
end # Resources
```

## Post command

You can run shell/ssh commands after building servers using `_post()`.

* Template
```ruby
Parameters do
  ...
end

Resources do
  ...
end

Outputs do
  MyPublicIp do
    Value { Fn__GetAtt name, "PublicIp" }
  end
end

_post do
  my_shell_command do
    command <<-EOS
      echo <%= Key "MyPublicIp" %>
    EOS
  end
  my_ssh_command do
    ssh do
      host { Key "MyPublicIp" } # or '<%= Key "MyPublicIp" %>'
      user "ec2-user"
      # see http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
      #options :timeout => 300
      #connect_tries 36
      #retry_interval 5
      #request_pty true
    end
    command <<-EOS
      hostname
    EOS
  end
end
```

* Execution result
```
...
Command: my_shell_command
Status: 0
1> 54.199.251.30

Command: my_ssh_command
Status: 0
1> ip-10-0-129-20

(Save to `/foo/bar/command_result.json`)
```

## Demo

* Create resources
  * https://asciinema.org/a/7979
* Convert a template
  * https://asciinema.org/a/7980
* Create a stack while outputting the event log
  * https://asciinema.org/a/8075
* Create a stack and run post commands
  * https://asciinema.org/a/8088

## Contributing

1. Fork it ( http://github.com/winebarrel/kumogata/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
