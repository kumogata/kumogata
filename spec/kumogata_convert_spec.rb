describe 'Kumogata::Client#convert' do
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

  it 'convert Ruby template to YAML template' do
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

    json_template = run_client(:convert, :template => template, :options => {:output_format => :yaml})

    expect(json_template).to eq((<<-EOS))
---
Resources:
  myEC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-XXXXXXXX
      InstanceType: t1.micro
Outputs:
  AZ:
    Value:
      Fn::GetAtt:
      - myEC2Instance
      - AvailabilityZone
    EOS
  end

  it 'convert YAML template to Ruby template' do
    template = <<-EOS
---
Resources:
  myEC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-XXXXXXXX
      InstanceType: t1.micro
Outputs:
  AZ:
    Value:
      Fn::GetAtt:
      - myEC2Instance
      - AvailabilityZone
    EOS

    ruby_template = run_client(:convert, :template => template, :template_ext => '.yml', :options => {:output_format => :ruby})

    expect(ruby_template).to eq((<<-EOS).chomp)
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

  it 'convert Ruby template to JavaScript template' do
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

    js_template = run_client(:convert, :template => template, :options => {:output_format => :js})

    expect(js_template).to eq <<-EOS.strip
({
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
})
    EOS
  end

  it 'convert JavaScript template to Ruby template' do
    template = <<-EOS
function fetch_ami() {
  return "ami-XXXXXXXX";
}

({
  Resources: { /* comment */
    myEC2Instance: {
      Type: "AWS::EC2::Instance",
      Properties: {
        ImageId: fetch_ami(),
        InstanceType: "t1.micro"
      }
    }
  },
  Outputs: {
    AZ: { /* comment */
      Value: {
        "Fn::GetAtt": [
          "myEC2Instance",
          "AvailabilityZone"
        ]
      }
    }
  }
})
    EOS

    ruby_template = run_client(:convert, :template => template, :template_ext => '.js', :options => {:output_format => :ruby})

    expect(ruby_template).to eq((<<-EOS).chomp)
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

  it 'convert Ruby template to JSON5 template' do
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

    js_template = run_client(:convert, :template => template, :options => {:output_format => :json5})

    expect(js_template).to eq <<-EOS.strip
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

  it 'convert JSON5 template to Ruby template' do
    template = <<-EOS
{
  Resources: { /* comment */
    myEC2Instance: {
      Type: "AWS::EC2::Instance",
      Properties: {
        ImageId: "ami-XXXXXXXX",
        InstanceType: "t1.micro"
      }
    }
  },
  Outputs: {
    AZ: { /* comment */
      Value: {
        "Fn::GetAtt": [
          "myEC2Instance",
          "AvailabilityZone"
        ]
      }
    }
  }
}
    EOS

    ruby_template = run_client(:convert, :template => template, :template_ext => '.json5', :options => {:output_format => :ruby})

    expect(ruby_template).to eq((<<-EOS).chomp)
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

  it 'convert JavaScript template to Ruby template' do
    template = <<-EOS
fetch_ami = () -> "ami-XXXXXXXX"

# comment
return {
  Resources:
    myEC2Instance:
      Type: "AWS::EC2::Instance",
      Properties:
        ImageId: fetch_ami(),
        InstanceType: "t1.micro"
  Outputs:
    AZ: # comment
      Value:
        "Fn::GetAtt": [
          "myEC2Instance",
          "AvailabilityZone"
        ]
}
    EOS

    ruby_template = run_client(:convert, :template => template, :template_ext => '.coffee', :options => {:output_format => :ruby})

    expect(ruby_template).to eq((<<-EOS).chomp)
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

  it 'convert YAML template to JSON template' do
    template = <<-EOS
---
Resources:
  myEC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-XXXXXXXX
      InstanceType: t1.micro
Outputs:
  AZ:
    Value:
      Fn::GetAtt:
      - myEC2Instance
      - AvailabilityZone
    EOS

    ruby_template = run_client(:convert, :template => template, :template_ext => '.yml', :options => {:output_format => :json})

    expect(ruby_template).to eq((<<-EOS).chomp)
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

  it 'convert JSON template to Ruby template' do
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

  it 'convert JSON template to YAML template' do
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

    ruby_template = run_client(:convert, :template => template, :template_ext => '.template', :options => {:output_format => :yaml})

    expect(ruby_template).to eq((<<-EOS))
---
Resources:
  myEC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-XXXXXXXX
      InstanceType: t1.micro
Outputs:
  AZ:
    Value:
      Fn::GetAtt:
      - myEC2Instance
      - AvailabilityZone
    EOS
  end

  it 'convert Ruby template to JSON template with fn_join()' do
    template = <<-TEMPLATE
Parameters do
  Password do
    NoEcho true
    Type "String"
  end
end

Resources do
  myEC2Instance do
    Type "AWS::EC2::Instance"
    Properties do
      ImageId "ami-XXXXXXXX"
      InstanceType "t1.micro"

      UserData do
        Fn__Base64 (<<-EOS).fn_join
          #!/bin/bash
          echo START | logger
          /opt/aws/bin/cfn-init -s <%= Ref "AWS::StackName" %> -r myEC2Instance --region <%= Ref "AWS::Region" %>
          echo END | logger
        EOS
      end
    end

    Metadata do
      AWS__CloudFormation__Init do
        config do

          packages do
            yum({"httpd"=>[]})
          end

          services do
            sysvinit do
              httpd do
                enabled "true"
                ensureRunning "true"
              end
            end
          end

          commands do
            any_name do
              command (<<-EOS).fn_join
                echo <%= Ref "Password" %> > /tmp/my-password
              EOS
            end
          end

        end # config
      end # AWS__CloudFormation__Init
    end # Metadata
  end
end
    TEMPLATE

    json_template = run_client(:convert, :template => template)

    expect(json_template).to eq((<<-'EOS').chomp)
{
  "Parameters": {
    "Password": {
      "NoEcho": "true",
      "Type": "String"
    }
  },
  "Resources": {
    "myEC2Instance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": "ami-XXXXXXXX",
        "InstanceType": "t1.micro",
        "UserData": {
          "Fn::Base64": {
            "Fn::Join": [
              "",
              [
                "#!/bin/bash\n",
                "echo START | logger\n",
                "/opt/aws/bin/cfn-init -s ",
                {
                  "Ref": "AWS::StackName"
                },
                " -r myEC2Instance --region ",
                {
                  "Ref": "AWS::Region"
                },
                "\n",
                "echo END | logger\n"
              ]
            ]
          }
        }
      },
      "Metadata": {
        "AWS::CloudFormation::Init": {
          "config": {
            "packages": {
              "yum": {
                "httpd": [

                ]
              }
            },
            "services": {
              "sysvinit": {
                "httpd": {
                  "enabled": "true",
                  "ensureRunning": "true"
                }
              }
            },
            "commands": {
              "any_name": {
                "command": {
                  "Fn::Join": [
                    "",
                    [
                      "echo ",
                      {
                        "Ref": "Password"
                      },
                      " > /tmp/my-password\n"
                    ]
                  ]
                }
              }
            }
          }
        }
      }
    }
  }
}
    EOS
  end

  it 'convert Ruby template to JSON template with converting user_data' do
    template = <<-TEMPLATE
Parameters do
  Password do
    NoEcho true
    Type "String"
  end
end

Resources do
  myEC2Instance do
    Type "AWS::EC2::Instance"
    Properties do
      ImageId "ami-XXXXXXXX"
      InstanceType "t1.micro"

      UserData (<<-EOS).undent.encode64
        #!/bin/bash
        yum install -y httpd
        services start httpd
      EOS
    end
  end
end
    TEMPLATE

    json_template = run_client(:convert, :template => template)

    # UserData: IyEvYmluL2Jhc2gKeXVtIGluc3RhbGwgLXkgaHR0cGQKc2VydmljZXMgc3RhcnQgaHR0cGQK
    # => #!/bin/bash
    #    yum install -y httpd
    #    services start httpd
    expect(json_template).to eq((<<-EOS).chomp)
{
  "Parameters": {
    "Password": {
      "NoEcho": "true",
      "Type": "String"
    }
  },
  "Resources": {
    "myEC2Instance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": "ami-XXXXXXXX",
        "InstanceType": "t1.micro",
        "UserData": "IyEvYmluL2Jhc2gKeXVtIGluc3RhbGwgLXkgaHR0cGQKc2VydmljZXMgc3RhcnQgaHR0cGQK"
      }
    }
  }
}
    EOS
  end

  it 'convert Ruby template to JSON template with block args' do
    template = <<-'TEMPLATE'
Parameters do
  Password do
    NoEcho true
    Type "String"
  end
end

Resources do
  myEC2Instance do |resource_name|
    Type "AWS::EC2::Instance"
    Properties do
      ImageId "ami-XXXXXXXX"
      InstanceType "t1.micro"

      UserData do
        Fn__Base64 (<<-EOS).fn_join
          #!/bin/bash
          echo START | logger
          /opt/aws/bin/cfn-init -s <%= Ref "AWS::StackName" %> -r #{resource_name} --region <%= Ref "AWS::Region" %>
          echo END | logger
        EOS
      end
    end

    Metadata do
      AWS__CloudFormation__Init do
        config do

          packages do
            yum({"httpd"=>[]})
          end

          services do
            sysvinit do
              httpd do
                enabled "true"
                ensureRunning "true"
              end
            end
          end

          commands do
            any_name do
              command (<<-EOS).fn_join
                echo <%= Ref "Password" %> > /tmp/my-password
              EOS
            end
          end

        end # config
      end # AWS__CloudFormation__Init
    end # Metadata
  end
end

Outputs do
  WebsiteURL do
    Value (<<-EOS).fn_join
      http://<%= Fn__GetAtt "myEC2Instance", "PublicDnsName" %>
    EOS
  end

  Base64Str do
    Value (<<-EOS).fn_join
      <%= Fn__Base64 "AWS CloudFormation" %>
    EOS
  end

  MappedValue do
    Value (<<-EOS).fn_join
      <%= Fn__FindInMap "RegionMap", _{ Ref "AWS::Region" }, 32 %>
    EOS
  end

  AZ do
    Value (<<-EOS).fn_join
      <%= Fn__GetAZs "us-east-1" %>
    EOS
  end
end
    TEMPLATE

    json_template = run_client(:convert, :template => template)

    expect(json_template).to eq((<<-'EOS').chomp)
{
  "Parameters": {
    "Password": {
      "NoEcho": "true",
      "Type": "String"
    }
  },
  "Resources": {
    "myEC2Instance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": "ami-XXXXXXXX",
        "InstanceType": "t1.micro",
        "UserData": {
          "Fn::Base64": {
            "Fn::Join": [
              "",
              [
                "#!/bin/bash\n",
                "echo START | logger\n",
                "/opt/aws/bin/cfn-init -s ",
                {
                  "Ref": "AWS::StackName"
                },
                " -r myEC2Instance --region ",
                {
                  "Ref": "AWS::Region"
                },
                "\n",
                "echo END | logger\n"
              ]
            ]
          }
        }
      },
      "Metadata": {
        "AWS::CloudFormation::Init": {
          "config": {
            "packages": {
              "yum": {
                "httpd": [

                ]
              }
            },
            "services": {
              "sysvinit": {
                "httpd": {
                  "enabled": "true",
                  "ensureRunning": "true"
                }
              }
            },
            "commands": {
              "any_name": {
                "command": {
                  "Fn::Join": [
                    "",
                    [
                      "echo ",
                      {
                        "Ref": "Password"
                      },
                      " > /tmp/my-password\n"
                    ]
                  ]
                }
              }
            }
          }
        }
      }
    }
  },
  "Outputs": {
    "WebsiteURL": {
      "Value": {
        "Fn::Join": [
          "",
          [
            "http://",
            {
              "Fn::GetAtt": [
                "myEC2Instance",
                "PublicDnsName"
              ]
            },
            "\n"
          ]
        ]
      }
    },
    "Base64Str": {
      "Value": {
        "Fn::Join": [
          "",
          [
            {
              "Fn::Base64": "AWS CloudFormation"
            },
            "\n"
          ]
        ]
      }
    },
    "MappedValue": {
      "Value": {
        "Fn::Join": [
          "",
          [
            {
              "Fn::FindInMap": [
                "RegionMap",
                {
                  "Ref": "AWS::Region"
                },
                "32"
              ]
            },
            "\n"
          ]
        ]
      }
    },
    "AZ": {
      "Value": {
        "Fn::Join": [
          "",
          [
            {
              "Fn::GetAZs": "us-east-1"
            },
            "\n"
          ]
        ]
      }
    }
  }
}
    EOS
  end

  it 'convert splitted Ruby template to JSON template' do
    json_template = nil

    part_of_template = <<-EOS
myEC2Instance do
  Type "AWS::EC2::Instance"
  Properties do
    ImageId "ami-XXXXXXXX"
    InstanceType "t1.micro"
  end
end
    EOS

    tempfile(part_of_template, '.rb') do |f|
      template = <<-EOS
Resources do
  _include #{f.path.inspect}
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
    end

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

  it 'convert splitted Ruby template to JSON template with args' do
    json_template = nil

    part_of_template = <<-EOS
myEC2Instance do
  Type "AWS::EC2::Instance"
  Properties do
    ImageId args[:ami_id]
    InstanceType "t1.micro"
  end
end
    EOS

    tempfile(part_of_template, '.rb') do |f|
      template = <<-EOS
Resources do
  _include #{f.path.inspect}, {:ami_id => "ami-XXXXXXXX"}
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
    end

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

  it 'convert Ruby template to JSON template with require' do
    template = <<-EOS
require 'fileutils'

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


  it 'convert splitted Ruby template to JSON template' do
    json_template = nil

    part_of_template = <<-EOS
myEC2Instance do
  Type "AWS::EC2::Instance"
  Properties do
    ImageId "ami-XXXXXXXX"
    InstanceType "t1.micro"
  end
end
    EOS

    tempfile(part_of_template, '.rb') do |f|
      template = <<-EOS
Resources do
  _include #{f.path.inspect}
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
    end

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

  let(:drupal_single_instance_template) do
    path = File.expand_path('../Drupal_Single_Instance.template', __FILE__)
    open(path) {|f| f.read }
  end

  let(:drupal_single_instance_template_rb) do
    path = File.expand_path('../Drupal_Single_Instance.template.rb', __FILE__)
    open(path) {|f| f.read }
  end

  it 'Ruby templates and JSON template should be same' do
    json_template = JSON.parse(drupal_single_instance_template)
    ruby_template = run_client(:convert, :template => drupal_single_instance_template_rb)
    ruby_template = JSON.parse(ruby_template)

    expect(ruby_template).to eq(json_template)
  end

  let(:vpc_knowhow_2014_04_template) do
    path = File.expand_path('../vpc-knowhow-2014-04.template', __FILE__)
    open(path) {|f| f.read }
  end

  it 'convert JSON template to Ruby template (include yum key)' do
    ruby_template = run_client(:convert, :template => vpc_knowhow_2014_04_template, :template_ext => '.template')

    expect(ruby_template).to eq <<-'EOS'.strip
AWSTemplateFormatVersion "2010-09-09"
Description "VPC knowhow template"
Parameters do
  KeyName do
    Description "Name of an existing EC2 KeyPair to enable SSH access to the instances"
    Type "String"
    MinLength 1
    MaxLength 64
    AllowedPattern "[-_ a-zA-Z0-9]*"
    ConstraintDescription "can contain only alphanumeric characters, spaces, dashes and underscores."
  end
  SSHFrom do
    Description "Lockdown SSH access to the bastion host (default can be accessed from anywhere)"
    Type "String"
    MinLength 9
    MaxLength 18
    Default "0.0.0.0/0"
    AllowedPattern "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})"
    ConstraintDescription "must be a valid CIDR range of the form x.x.x.x/x."
  end
  DBInstanceType do
    Description "EC2 instance type for the Blue environment"
    Default "db.t1.micro"
    Type "String"
  end
  DBSnapshotName do
    Default ""
    Description "The name of a DB snapshot (optional)"
    Type "String"
  end
  DBAllocatedStorage do
    Default 5
    Description "DB instance disk size"
    Type "Number"
  end
  DBUsername do
    Default "admin"
    Description "The database master account username"
    Type "String"
    MinLength 1
    MaxLength 16
    AllowedPattern "[a-zA-Z][a-zA-Z0-9]*"
    ConstraintDescription "must begin with a letter and contain only alphanumeric characters."
  end
  DBPassword do
    Description "Password of RDS master password"
    Type "String"
    NoEcho "true"
    MinLength 4
  end
  DBName do
    Default ""
    Description "The name of a DB01 database"
    Type "String"
  end
  WebInstanceType do
    Description "EC2 instance type for the web server"
    Default "t1.micro"
    Type "String"
  end
  WebFleetSize do
    Description "Number of EC2 instances to launch for the web server"
    Default 2
    Type "Number"
    MaxValue 100
    MinValue 1
  end
  HostedZone do
    Description "The DNS name of an existing Amazon Route 53 hosted zone"
    Type "String"
  end
end
Conditions do
  UseDBSnapshot do
    Fn__Not [
      _{
        Fn__Equals [
          _{
            Ref "DBSnapshotName"
          },
          ""
        ]
      }
    ]
  end
end
Mappings do
  AWSAmazonLinuxAMI(
    {"us-east-1"=>
      {"name"=>"Virginia",
       "201303"=>"ami-3275ee5b",
       "201309"=>"ami-35792c5c",
       "201403"=>"ami-2f726546"},
     "us-west-2"=>
      {"name"=>"Oregon",
       "201303"=>"ami-ecbe2adc",
       "201309"=>"ami-d03ea1e0",
       "201403"=>"ami-b8f69f88"},
     "us-west-1"=>
      {"name"=>"California",
       "201303"=>"ami-66d1fc23",
       "201309"=>"ami-687b4f2d",
       "201403"=>"ami-84f1cfc1"},
     "eu-west-1"=>
      {"name"=>"Ireland",
       "201303"=>"ami-44939930",
       "201309"=>"ami-149f7863",
       "201403"=>"ami-a921dfde"},
     "ap-southeast-1"=>
      {"name"=>"Singapole",
       "201303"=>"ami-aa9ed2f8",
       "201309"=>"ami-14f2b946",
       "201403"=>"ami-787c2c2a"},
     "ap-southeast-2"=>
      {"name"=>"Sydney",
       "201303"=>"ami-363eaf0c",
       "201309"=>"ami-a148d59b",
       "201403"=>"ami-0bc85031"},
     "ap-northeast-1"=>
      {"name"=>"Tokyo",
       "201303"=>"ami-173fbf16",
       "201309"=>"ami-3561fe34",
       "201403"=>"ami-a1bec3a0"},
     "sa-east-1"=>
      {"name"=>"SaoPaulo",
       "201303"=>"ami-dd6bb0c0",
       "201309"=>"ami-9f6ec982",
       "201403"=>"ami-89de7c94"}})
  ELBLogger(
    {"us-east-1"=>{"AccountID"=>"127311923021"},
     "us-west-2"=>{"AccountID"=>"797873946194"},
     "us-west-1"=>{"AccountID"=>"027434742980"},
     "eu-west-1"=>{"AccountID"=>"156460612806"},
     "ap-southeast-1"=>{"AccountID"=>"114774131450"},
     "ap-southeast-2"=>{"AccountID"=>"783225319266"},
     "ap-northeast-1"=>{"AccountID"=>"582318560864"},
     "sa-east-1"=>{"AccountID"=>"507241528517"},
     "us-gov-west-1"=>{"AccountID"=>"048591011584"}})
  StackConfig do
    VPC do
      CIDR "10.0.0.0/16"
    end
    FrontendSubnet1 do
      CIDR "10.0.0.0/24"
    end
    FrontendSubnet2 do
      CIDR "10.0.1.0/24"
    end
    ApplicationSubnet1 do
      CIDR "10.0.100.0/24"
    end
    ApplicationSubnet2 do
      CIDR "10.0.101.0/24"
    end
    DatastoreSubnet1 do
      CIDR "10.0.200.0/24"
    end
    DatastoreSubnet2 do
      CIDR "10.0.201.0/24"
    end
    BastionServer do
      InstanceType "t1.micro"
    end
  end
end
Resources do
  PowerUserRole do
    Type "AWS::IAM::Role"
    Properties do
      AssumeRolePolicyDocument do
        Statement [
          _{
            Effect "Allow"
            Principal do
              Service ["ec2.amazonaws.com"]
            end
            Action ["sts:AssumeRole"]
          }
        ]
      end
      Path "/"
      Policies [
        _{
          PolicyName "PowerUserPolicy"
          PolicyDocument do
            Statement [
              _{
                Sid "PowerUserStmt"
                Effect "Allow"
                NotAction "iam:*"
                Resource "*"
              }
            ]
          end
        }
      ]
    end
  end
  PowerUserProfile do
    Type "AWS::IAM::InstanceProfile"
    Properties do
      Path "/"
      Roles [
        _{
          Ref "PowerUserRole"
        }
      ]
    end
  end
  LogBucket do
    Type "AWS::S3::Bucket"
    DeletionPolicy "Retain"
  end
  LogBucketPolicy do
    Type "AWS::S3::BucketPolicy"
    Properties do
      Bucket do
        Ref "LogBucket"
      end
      PolicyDocument do
        Id "LogBucketPolicy"
        Statement [
          _{
            Sid "WriteAccess"
            Action ["s3:PutObject"]
            Effect "Allow"
            Resource do
              Fn__Join [
                "",
                [
                  "arn:aws:s3:::",
                  _{
                    Ref "LogBucket"
                  },
                  "/AWSLogs/",
                  _{
                    Ref "AWS::AccountId"
                  },
                  "/*"
                ]
              ]
            end
            Principal do
              AWS do
                Fn__FindInMap [
                  "ELBLogger",
                  _{
                    Ref "AWS::Region"
                  },
                  "AccountID"
                ]
              end
            end
          }
        ]
      end
    end
  end
  VPC do
    Type "AWS::EC2::VPC"
    Properties do
      CidrBlock do
        Fn__FindInMap "StackConfig", "VPC", "CIDR"
      end
      EnableDnsSupport "true"
      EnableDnsHostnames "true"
      InstanceTenancy "default"
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackId"
          end
        },
        _{
          Key "Network"
          Value "Public"
        }
      ]
    end
  end
  InternetGateway do
    Type "AWS::EC2::InternetGateway"
    Properties do
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackId"
          end
        },
        _{
          Key "Network"
          Value "Public"
        }
      ]
    end
  end
  AttachGateway do
    Type "AWS::EC2::VPCGatewayAttachment"
    Properties do
      VpcId do
        Ref "VPC"
      end
      InternetGatewayId do
        Ref "InternetGateway"
      end
    end
  end
  PublicRouteTable do
    Type "AWS::EC2::RouteTable"
    DependsOn "AttachGateway"
    Properties do
      VpcId do
        Ref "VPC"
      end
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackId"
          end
        },
        _{
          Key "Network"
          Value "Public"
        }
      ]
    end
  end
  PrivateRouteTable do
    Type "AWS::EC2::RouteTable"
    DependsOn "AttachGateway"
    Properties do
      VpcId do
        Ref "VPC"
      end
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackId"
          end
        },
        _{
          Key "Network"
          Value "Private"
        }
      ]
    end
  end
  PublicRoute do
    Type "AWS::EC2::Route"
    DependsOn "AttachGateway"
    Properties do
      RouteTableId do
        Ref "PublicRouteTable"
      end
      DestinationCidrBlock "0.0.0.0/0"
      GatewayId do
        Ref "InternetGateway"
      end
    end
  end
  FrontendSubnet1 do
    Type "AWS::EC2::Subnet"
    DependsOn "AttachGateway"
    Properties do
      VpcId do
        Ref "VPC"
      end
      AvailabilityZone do
        Fn__Select [
          "0",
          _{
            Fn__GetAZs do
              Ref "AWS::Region"
            end
          }
        ]
      end
      CidrBlock do
        Fn__FindInMap "StackConfig", "FrontendSubnet1", "CIDR"
      end
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackId"
          end
        },
        _{
          Key "Network"
          Value "Public"
        }
      ]
    end
  end
  FrontendSubnet2 do
    Type "AWS::EC2::Subnet"
    DependsOn "AttachGateway"
    Properties do
      VpcId do
        Ref "VPC"
      end
      AvailabilityZone do
        Fn__Select [
          "1",
          _{
            Fn__GetAZs do
              Ref "AWS::Region"
            end
          }
        ]
      end
      CidrBlock do
        Fn__FindInMap "StackConfig", "FrontendSubnet2", "CIDR"
      end
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackId"
          end
        },
        _{
          Key "Network"
          Value "Public"
        }
      ]
    end
  end
  ApplicationSubnet1 do
    Type "AWS::EC2::Subnet"
    DependsOn "AttachGateway"
    Properties do
      VpcId do
        Ref "VPC"
      end
      CidrBlock do
        Fn__FindInMap "StackConfig", "ApplicationSubnet1", "CIDR"
      end
      AvailabilityZone do
        Fn__Select [
          "0",
          _{
            Fn__GetAZs do
              Ref "AWS::Region"
            end
          }
        ]
      end
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackId"
          end
        },
        _{
          Key "Network"
          Value "Public"
        }
      ]
    end
  end
  ApplicationSubnet2 do
    Type "AWS::EC2::Subnet"
    DependsOn "AttachGateway"
    Properties do
      VpcId do
        Ref "VPC"
      end
      CidrBlock do
        Fn__FindInMap "StackConfig", "ApplicationSubnet2", "CIDR"
      end
      AvailabilityZone do
        Fn__Select [
          "1",
          _{
            Fn__GetAZs do
              Ref "AWS::Region"
            end
          }
        ]
      end
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackId"
          end
        },
        _{
          Key "Network"
          Value "Public"
        }
      ]
    end
  end
  DatastoreSubnet1 do
    Type "AWS::EC2::Subnet"
    DependsOn "AttachGateway"
    Properties do
      VpcId do
        Ref "VPC"
      end
      CidrBlock do
        Fn__FindInMap "StackConfig", "DatastoreSubnet1", "CIDR"
      end
      AvailabilityZone do
        Fn__Select [
          "0",
          _{
            Fn__GetAZs do
              Ref "AWS::Region"
            end
          }
        ]
      end
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackId"
          end
        },
        _{
          Key "Network"
          Value "Private"
        }
      ]
    end
  end
  DatastoreSubnet2 do
    Type "AWS::EC2::Subnet"
    DependsOn "AttachGateway"
    Properties do
      VpcId do
        Ref "VPC"
      end
      CidrBlock do
        Fn__FindInMap "StackConfig", "DatastoreSubnet2", "CIDR"
      end
      AvailabilityZone do
        Fn__Select [
          "1",
          _{
            Fn__GetAZs do
              Ref "AWS::Region"
            end
          }
        ]
      end
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackId"
          end
        },
        _{
          Key "Network"
          Value "Private"
        }
      ]
    end
  end
  FrontendSubnet1RouteTableAssociation do
    Type "AWS::EC2::SubnetRouteTableAssociation"
    Properties do
      SubnetId do
        Ref "FrontendSubnet1"
      end
      RouteTableId do
        Ref "PublicRouteTable"
      end
    end
  end
  FrontendSubnet2RouteTableAssociation do
    Type "AWS::EC2::SubnetRouteTableAssociation"
    Properties do
      SubnetId do
        Ref "FrontendSubnet2"
      end
      RouteTableId do
        Ref "PublicRouteTable"
      end
    end
  end
  ApplicationSubnet1RouteTableAssociation do
    Type "AWS::EC2::SubnetRouteTableAssociation"
    Properties do
      SubnetId do
        Ref "ApplicationSubnet1"
      end
      RouteTableId do
        Ref "PublicRouteTable"
      end
    end
  end
  ApplicationSubnet2RouteTableAssociation do
    Type "AWS::EC2::SubnetRouteTableAssociation"
    Properties do
      SubnetId do
        Ref "ApplicationSubnet2"
      end
      RouteTableId do
        Ref "PublicRouteTable"
      end
    end
  end
  DatastoreSubnet1RouteTableAssociation do
    Type "AWS::EC2::SubnetRouteTableAssociation"
    Properties do
      SubnetId do
        Ref "DatastoreSubnet1"
      end
      RouteTableId do
        Ref "PrivateRouteTable"
      end
    end
  end
  DatastoreSubnet2RouteTableAssociation do
    Type "AWS::EC2::SubnetRouteTableAssociation"
    Properties do
      SubnetId do
        Ref "DatastoreSubnet2"
      end
      RouteTableId do
        Ref "PrivateRouteTable"
      end
    end
  end
  VPCDefaultSecurityGroup do
    Type "AWS::EC2::SecurityGroup"
    Properties do
      VpcId do
        Ref "VPC"
      end
      GroupDescription "Allow all communications in VPC"
      SecurityGroupIngress [
        _{
          IpProtocol "tcp"
          FromPort 0
          ToPort 65535
          CidrIp do
            Fn__FindInMap "StackConfig", "VPC", "CIDR"
          end
        },
        _{
          IpProtocol "udp"
          FromPort 0
          ToPort 65535
          CidrIp do
            Fn__FindInMap "StackConfig", "VPC", "CIDR"
          end
        },
        _{
          IpProtocol "icmp"
          FromPort "-1"
          ToPort "-1"
          CidrIp do
            Fn__FindInMap "StackConfig", "VPC", "CIDR"
          end
        }
      ]
    end
  end
  SSHSecurityGroup do
    Type "AWS::EC2::SecurityGroup"
    Properties do
      VpcId do
        Ref "VPC"
      end
      GroupDescription "Enable SSH access via port 22"
      SecurityGroupIngress [
        _{
          IpProtocol "tcp"
          FromPort 22
          ToPort 22
          CidrIp do
            Ref "SSHFrom"
          end
        }
      ]
    end
  end
  PublicWebSecurityGroup do
    Type "AWS::EC2::SecurityGroup"
    Properties do
      VpcId do
        Ref "VPC"
      end
      GroupDescription "Public Security Group with HTTP access on port 443 from the internet"
      SecurityGroupIngress [
        _{
          IpProtocol "tcp"
          FromPort 80
          ToPort 80
          CidrIp "0.0.0.0/0"
        },
        _{
          IpProtocol "tcp"
          FromPort 443
          ToPort 443
          CidrIp "0.0.0.0/0"
        }
      ]
    end
  end
  ApplicationSecurityGroup do
    Type "AWS::EC2::SecurityGroup"
    Properties do
      VpcId do
        Ref "VPC"
      end
      GroupDescription "Marker security group for Application server."
    end
  end
  MySQLSecurityGroup do
    Type "AWS::EC2::SecurityGroup"
    Properties do
      VpcId do
        Ref "VPC"
      end
      GroupDescription "Marker security group for MySQL server."
    end
  end
  BastionWaitHandle do
    Type "AWS::CloudFormation::WaitConditionHandle"
  end
  BastionWaitCondition do
    Type "AWS::CloudFormation::WaitCondition"
    DependsOn "BastionInstance"
    Properties do
      Handle do
        Ref "BastionWaitHandle"
      end
      Timeout 900
    end
  end
  BastionInstance do
    Type "AWS::EC2::Instance"
    Properties do
      InstanceType do
        Fn__FindInMap "StackConfig", "BastionServer", "InstanceType"
      end
      KeyName do
        Ref "KeyName"
      end
      SubnetId do
        Ref "FrontendSubnet1"
      end
      ImageId do
        Fn__FindInMap [
          "AWSAmazonLinuxAMI",
          _{
            Ref "AWS::Region"
          },
          "201403"
        ]
      end
      IamInstanceProfile do
        Ref "PowerUserProfile"
      end
      SecurityGroupIds [
        _{
          Ref "SSHSecurityGroup"
        },
        _{
          Ref "VPCDefaultSecurityGroup"
        }
      ]
      Tags [
        _{
          Key "Name"
          Value "Bastion"
        }
      ]
      UserData do
        Fn__Base64 do
          Fn__Join [
            "",
            [
              "#! /bin/bash -v\n",
              "yum update -y\n",
              "# Helper function\n",
              "function error_exit\n",
              "{\n",
              "  /opt/aws/bin/cfn-signal -e 1 -r \"$1\" '",
              _{
                Ref "BastionWaitHandle"
              },
              "'\n",
              "  exit 1\n",
              "}\n",
              "# Install packages\n",
              "/opt/aws/bin/cfn-init -s ",
              _{
                Ref "AWS::StackId"
              },
              " -r BastionInstance ",
              "    --region ",
              _{
                Ref "AWS::Region"
              },
              " || error_exit 'Failed to run cfn-init'\n",
              "# All is well so signal success\n",
              "/opt/aws/bin/cfn-signal -e $? -r \"BastionInstance setup complete\" '",
              _{
                Ref "BastionWaitHandle"
              },
              "'\n"
            ]
          ]
        end
      end
    end
    Metadata do
      AWS__CloudFormation__Init do
        config do
          packages do
            yum(
              {"mysql55"=>[], "jq"=>[], "python-magic"=>[]})
          end
        end
      end
    end
  end
  BastionInstanceEIP do
    Type "AWS::EC2::EIP"
    DependsOn "AttachGateway"
    Properties do
      Domain "vpc"
      InstanceId do
        Ref "BastionInstance"
      end
    end
  end
  BastionDNSRecord do
    Type "AWS::Route53::RecordSet"
    Properties do
      HostedZoneName do
        Fn__Join [
          "",
          [
            _{
              Ref "HostedZone"
            },
            "."
          ]
        ]
      end
      Comment "A record for the Bastion instance."
      Name do
        Fn__Join [
          "",
          [
            "bastion.",
            _{
              Ref "HostedZone"
            },
            "."
          ]
        ]
      end
      Type "A"
      TTL 300
      ResourceRecords [
        _{
          Ref "BastionInstanceEIP"
        }
      ]
    end
  end
  BastionLocalDNSRecord do
    Type "AWS::Route53::RecordSet"
    Properties do
      HostedZoneName do
        Fn__Join [
          "",
          [
            _{
              Ref "HostedZone"
            },
            "."
          ]
        ]
      end
      Comment "A record for the private IP address of Bastion instance."
      Name do
        Fn__Join [
          "",
          [
            "bastion.local.",
            _{
              Ref "HostedZone"
            },
            "."
          ]
        ]
      end
      Type "A"
      TTL 300
      ResourceRecords [
        _{
          Fn__GetAtt "BastionInstance", "PrivateIp"
        }
      ]
    end
  end
  DBParamGroup do
    Type "AWS::RDS::DBParameterGroup"
    Properties do
      Description "Default parameter group for Portnoy"
      Family "MySQL5.6"
      Parameters(
        {"character_set_database"=>"utf8mb4",
         "character_set_client"=>"utf8mb4",
         "character_set_connection"=>"utf8mb4",
         "character_set_results"=>"utf8mb4",
         "character_set_server"=>"utf8mb4",
         "skip-character-set-client-handshake"=>"TRUE"})
    end
  end
  DBSubnetGroup do
    Type "AWS::RDS::DBSubnetGroup"
    Properties do
      DBSubnetGroupDescription "Database subnets for RDS"
      SubnetIds [
        _{
          Ref "DatastoreSubnet1"
        },
        _{
          Ref "DatastoreSubnet2"
        }
      ]
    end
  end
  DBInstance do
    Type "AWS::RDS::DBInstance"
    DeletionPolicy "Snapshot"
    Properties do
      DBInstanceClass do
        Ref "DBInstanceType"
      end
      AllocatedStorage do
        Ref "DBAllocatedStorage"
      end
      Engine "MySQL"
      MultiAZ "true"
      EngineVersion "5.6.13"
      MasterUsername do
        Ref "DBUsername"
      end
      MasterUserPassword do
        Ref "DBPassword"
      end
      BackupRetentionPeriod 35
      DBParameterGroupName do
        Ref "DBParamGroup"
      end
      DBSubnetGroupName do
        Ref "DBSubnetGroup"
      end
      DBSnapshotIdentifier do
        Fn__If [
          "UseDBSnapshot",
          _{
            Ref "DBSnapshotName"
          },
          _{
            Ref "AWS::NoValue"
          }
        ]
      end
      PreferredBackupWindow "19:00-19:30"
      PreferredMaintenanceWindow "sat:20:00-sat:20:30"
      VPCSecurityGroups [
        _{
          Ref "VPCDefaultSecurityGroup"
        },
        _{
          Ref "MySQLSecurityGroup"
        }
      ]
    end
  end
  DatabaseDNSRecord do
    Type "AWS::Route53::RecordSet"
    Properties do
      HostedZoneName do
        Fn__Join [
          "",
          [
            _{
              Ref "HostedZone"
            },
            "."
          ]
        ]
      end
      Comment "CNAME for the database."
      Name do
        Fn__Join [
          "",
          [
            "db.local.",
            _{
              Ref "HostedZone"
            },
            "."
          ]
        ]
      end
      Type "CNAME"
      TTL 300
      ResourceRecords [
        _{
          Fn__GetAtt "DBInstance", "Endpoint.Address"
        }
      ]
    end
  end
  ApplicationFleet do
    Type "AWS::AutoScaling::AutoScalingGroup"
    UpdatePolicy do
      AutoScalingRollingUpdate do
        MaxBatchSize 1
        MinInstancesInService 1
        PauseTime "PT2M30S"
      end
    end
    Properties do
      AvailabilityZones [
        _{
          Fn__GetAtt "ApplicationSubnet1", "AvailabilityZone"
        },
        _{
          Fn__GetAtt "ApplicationSubnet2", "AvailabilityZone"
        }
      ]
      VPCZoneIdentifier [
        _{
          Ref "ApplicationSubnet1"
        },
        _{
          Ref "ApplicationSubnet2"
        }
      ]
      LaunchConfigurationName do
        Ref "ApplicationServerLaunchConfig"
      end
      MinSize do
        Ref "WebFleetSize"
      end
      MaxSize do
        Ref "WebFleetSize"
      end
      DesiredCapacity do
        Ref "WebFleetSize"
      end
      LoadBalancerNames [
        _{
          Ref "ElasticLoadBalancer"
        }
      ]
      Tags [
        _{
          Key "Name"
          Value "Application"
          PropagateAtLaunch "true"
        }
      ]
    end
  end
  ApplicationServerLaunchConfig do
    Type "AWS::AutoScaling::LaunchConfiguration"
    Properties do
      InstanceType do
        Ref "WebInstanceType"
      end
      KeyName do
        Ref "KeyName"
      end
      ImageId do
        Fn__FindInMap [
          "AWSAmazonLinuxAMI",
          _{
            Ref "AWS::Region"
          },
          "201403"
        ]
      end
      SecurityGroups [
        _{
          Ref "VPCDefaultSecurityGroup"
        },
        _{
          Ref "ApplicationSecurityGroup"
        }
      ]
      AssociatePublicIpAddress "true"
      IamInstanceProfile do
        Ref "PowerUserProfile"
      end
      InstanceMonitoring "false"
      UserData do
        Fn__Base64 do
          Fn__Join [
            "",
            [
              "#! /bin/bash -v\n",
              "yum update -y\n",
              "# Install packages\n",
              "/opt/aws/bin/cfn-init -s ",
              _{
                Ref "AWS::StackId"
              },
              " -r ApplicationServerLaunchConfig ",
              "    --region ",
              _{
                Ref "AWS::Region"
              },
              " || error_exit 'Failed to run cfn-init'\n"
            ]
          ]
        end
      end
    end
    Metadata do
      AWS__CloudFormation__Init do
        config do
          packages do
            yum(
              {"httpd"=>[], "mysql55"=>[]})
          end
          files do
            _path("/var/www/html/index.html") do
              content "<html><head><title>Hello</title></head><body>Hello, world!</body></html>"
              mode "000644"
              owner "apache"
              group "apache"
            end
          end
          services do
            sysvinit do
              httpd do
                enabled "true"
                ensureRunning "true"
              end
            end
          end
        end
      end
    end
  end
  ElasticLoadBalancer do
    Type "AWS::ElasticLoadBalancing::LoadBalancer"
    DependsOn "AttachGateway"
    Properties do
      Subnets [
        _{
          Ref "FrontendSubnet1"
        },
        _{
          Ref "FrontendSubnet2"
        }
      ]
      Listeners [
        _{
          LoadBalancerPort 80
          InstancePort 80
          Protocol "HTTP"
        }
      ]
      HealthCheck do
        Target "HTTP:80/index.html"
        HealthyThreshold 2
        UnhealthyThreshold 2
        Interval 6
        Timeout 5
      end
      SecurityGroups [
        _{
          Ref "PublicWebSecurityGroup"
        }
      ]
    end
  end
  LoadBalancerDNSRecord do
    Type "AWS::Route53::RecordSetGroup"
    Properties do
      HostedZoneName do
        Fn__Join [
          "",
          [
            _{
              Ref "HostedZone"
            },
            "."
          ]
        ]
      end
      Comment "Zone apex alias targeted to LoadBalancer."
      RecordSets [
        _{
          Name do
            Fn__Join [
              "",
              [
                _{
                  Ref "HostedZone"
                },
                "."
              ]
            ]
          end
          Type "A"
          AliasTarget do
            HostedZoneId do
              Fn__GetAtt "ElasticLoadBalancer", "CanonicalHostedZoneNameID"
            end
            DNSName do
              Fn__GetAtt "ElasticLoadBalancer", "CanonicalHostedZoneName"
            end
          end
        }
      ]
    end
  end
end
Outputs do
  JdbcConnectionString do
    Value do
      Fn__Join [
        "",
        [
          "jdbc:mysql://",
          _{
            Ref "DatabaseDNSRecord"
          },
          ":",
          _{
            Fn__GetAtt "DBInstance", "Endpoint.Port"
          },
          "/",
          _{
            Ref "DBName"
          }
        ]
      ]
    end
    Description "-"
  end
  SSHToBackendServer do
    Value do
      Fn__Join [
        "",
        [
          "ssh -i /path/to/",
          _{
            Ref "KeyName"
          },
          ".pem",
          " -oProxyCommand='ssh -i /path/to/",
          _{
            Ref "KeyName"
          },
          ".pem -W %h:%p ec2-user@",
          _{
            Ref "BastionDNSRecord"
          },
          "'",
          " ec2-user@<private-ip>"
        ]
      ]
    end
    Description "SSH command to connect to the backend servers"
  end
end
    EOS
  end
end
