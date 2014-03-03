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

  it 'convert Ruby template to JSON template with _join()' do
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
        Fn__Base64 _join(<<-EOS)
          #!/bin/bash
          /opt/aws/bin/cfn-init -s <%= Ref "AWS::StackName" %> -r myEC2Instance --region <%= Ref "AWS::Region" %>
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
              command _join(<<-EOS)
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
                "#!/bin/bash\n/opt/aws/bin/cfn-init -s ",
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
                      " > /tmp/my-password",
                      "\n"
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

  it 'convert Ruby template to JSON template with _user_data()' do
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

      UserData _user_data(<<-EOS)
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
end
