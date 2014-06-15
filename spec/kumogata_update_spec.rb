describe 'Kumogata::Client#update' do
  it 'update a stack from Ruby template' do
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

    run_client(:update, :arguments => ['MyStack'], :template => template) do |client, cf|
      json = eval_template(template).to_json
      client.should_receive(:print_event_log).once
      client.should_receive(:create_event_log).once

      output = make_double('output') do |obj|
        obj.should_receive(:key) { 'AZ' }
        obj.should_receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        obj.should_receive(:[]).with(:resource_status) { 'UPDATE_COMPLETE' }
        obj.should_receive(:[]).with(:resource_status_reason) { nil }
        obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:update).with(:template => json)
        obj.should_receive(:status).and_return(
            'UPDATE_COMPLETE', 'UPDATE_COMPLETE', 'UPDATE_COMPLETE')
        obj.should_receive(:outputs) { [output] }
        obj.should_receive(:resource_summaries) { [resource_summary] }
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[])
           .with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }
    end
  end

  it 'update a stack from Ruby template (detach)' do
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

    out = run_client(:update, :arguments => ['MyStack'], :template => template, :options => {:detach => true}) do |client, cf|
      json = eval_template(template).to_json
      client.should_not_receive(:print_event_log)
      client.should_receive(:create_event_log).once

      stack = make_double('stack') do |obj|
        obj.should_receive(:update).with(:template => json)
        obj.should_receive(:status).once
        obj.should_not_receive(:outputs)
        obj.should_not_receive(:resource_summaries)
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[])
           .with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }
    end

    expect(out).to eq(Kumogata::Client::DETACH_MESSAGE)
  end

  it 'update a stack from Ruby template with deletion policy retain' do
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

    Timecop.freeze(Time.utc(2014)) do
      run_client(:update, :arguments => ['MyStack'], :template => template, :options => {:deletion_policy_retain => true}) do |client, cf|
        template = eval_template(template, :update_deletion_policy => true)
        template["Resources"]["myEC2Instance"]["Metadata"] = {
          "DeletionPolicyUpdateKeyForKumogata" => "DeletionPolicyUpdateValueForKumogata1388534400"
        }
        json = template.to_json
        client.should_receive(:print_event_log).once
        client.should_receive(:create_event_log).once

        output = make_double('output') do |obj|
          obj.should_receive(:key) { 'AZ' }
          obj.should_receive(:value) { 'ap-northeast-1b' }
        end

        resource_summary = make_double('resource_summary') do |obj|
          obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
          obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
          obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
          obj.should_receive(:[]).with(:resource_status) { 'UPDATE_COMPLETE' }
          obj.should_receive(:[]).with(:resource_status_reason) { nil }
          obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
        end

        stack = make_double('stack') do |obj|
          obj.should_receive(:update).with(:template => json)
          obj.should_receive(:status).and_return(
              'UPDATE_COMPLETE', 'UPDATE_COMPLETE', 'UPDATE_COMPLETE')
          obj.should_receive(:outputs) { [output] }
          obj.should_receive(:resource_summaries) { [resource_summary] }
        end

        stacks = make_double('stacks') do |obj|
          obj.should_receive(:[])
             .with('MyStack') { stack }
        end

        cf.should_receive(:stacks) { stacks }
      end
    end
  end

  it 'update a stack from Ruby template and run command' do
    template = <<-TEMPLATE
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

  Region do
    Value do
      Ref "AWS::Region"
    end
  end
end

_post do
  command_a do
    command <<-EOS
      echo <%= Key "AZ" %>
      echo <%= Key "Region" %>
    EOS
  end
  command_b do
    command <<-EOS
      echo <%= Key "Region" %>
      echo <%= Key "AZ" %>
    EOS
  end
end
    TEMPLATE

    run_client(:update, :arguments => ['MyStack'], :template => template) do |client, cf|
      json = eval_template(template).to_json
      client.should_receive(:print_event_log).once
      client.should_receive(:create_event_log).once

      output1 = make_double('output') do |obj|
        obj.should_receive(:key) { 'AZ' }
        obj.should_receive(:value) { 'ap-northeast-1b' }
      end

      output2 = make_double('output') do |obj|
        obj.should_receive(:key) { 'Region' }
        obj.should_receive(:value) { 'ap-northeast-1' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        obj.should_receive(:[]).with(:resource_status) { 'UPDATE_COMPLETE' }
        obj.should_receive(:[]).with(:resource_status_reason) { nil }
        obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:update).with(:template => json)
        obj.should_receive(:status).and_return(
            'UPDATE_COMPLETE', 'UPDATE_COMPLETE', 'UPDATE_COMPLETE')
        obj.should_receive(:outputs) { [output1, output2] }
        obj.should_receive(:resource_summaries) { [resource_summary] }
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[])
           .with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }

      process_status1 = double('process_status1')
      process_status2 = double('process_status2')

      Open3.should_not_receive(:capture3)

      client.instance_variable_get(:@post_processing)
            .should_not_receive(:print_command_result)

      client.instance_variable_get(:@post_processing)
            .should_not_receive(:save_command_results)
    end
  end

  it 'update a stack from Ruby template and run ssh command' do
    template = <<-TEMPLATE
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
  PublicIp do
    Value do
      Fn__GetAtt "myEC2Instance", "PublicIp"
    end
  end
end

_post do
  ssh_command do
    after :update
    ssh do
      host { Key "PublicIp" }
      user "ec2-user"
    end
    command <<-EOS
      ls
    EOS
  end
end
    TEMPLATE

    run_client(:update, :arguments => ['MyStack'], :template => template) do |client, cf|
      json = eval_template(template).to_json
      client.should_receive(:print_event_log).once
      client.should_receive(:create_event_log).once

      output = make_double('output') do |obj|
        obj.should_receive(:key) { 'PublicIp' }
        obj.should_receive(:value) { '127.0.0.1' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        obj.should_receive(:[]).with(:resource_status) { 'UPDATE_COMPLETE' }
        obj.should_receive(:[]).with(:resource_status_reason) { nil }
        obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:update).with(:template => json)
        obj.should_receive(:status).and_return(
            'UPDATE_COMPLETE', 'UPDATE_COMPLETE', 'UPDATE_COMPLETE')
        obj.should_receive(:outputs) { [output] }
        obj.should_receive(:resource_summaries) { [resource_summary] }
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[])
           .with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }

      client.instance_variable_get(:@post_processing)
           .should_receive(:run_ssh_command)
           .with({"host"=>"<%= Key \"PublicIp\" %>", "user"=>"ec2-user", "request_pty"=>true}, "      ls\n", {"PublicIp"=>"127.0.0.1"})
           .and_return(["file1\nfile2\n", "", 0])

      client.instance_variable_get(:@post_processing)
            .should_receive(:print_command).with('ssh_command')

      client.instance_variable_get(:@post_processing)
            .should_receive(:print_command_result)
            .with("file1\nfile2\n", "", 0)

      client.instance_variable_get(:@post_processing)
            .should_receive(:save_command_results)
            .with([{'ssh_command' => {'ExitStatus' => 0, 'StdOut' => "file1\nfile2\n", 'StdErr' => ""}}])
    end
  end

  it 'update a stack from Ruby template and run ssh command (modify outputs)' do
    template = <<-TEMPLATE
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
  PublicIp do
    Value do
      Fn__GetAtt "myEC2Instance", "PublicIp"
    end
  end
end

_outputs_filter do |outputs|
  outputs['PublicIp'].gsub!('.', '-')
end

_post do
  ssh_command do
    after :update
    ssh do
      host { Key "PublicIp" }
      user "ec2-user"
    end
    command <<-EOS
      ls
    EOS
  end
end
    TEMPLATE

    run_client(:update, :arguments => ['MyStack'], :template => template) do |client, cf|
      json = eval_template(template).to_json
      client.should_receive(:print_event_log).once
      client.should_receive(:create_event_log).once

      output = make_double('output') do |obj|
        obj.should_receive(:key) { 'PublicIp' }
        obj.should_receive(:value) { '127.0.0.1' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        obj.should_receive(:[]).with(:resource_status) { 'UPDATE_COMPLETE' }
        obj.should_receive(:[]).with(:resource_status_reason) { nil }
        obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:update).with(:template => json)
        obj.should_receive(:status).and_return(
            'UPDATE_COMPLETE', 'UPDATE_COMPLETE', 'UPDATE_COMPLETE')
        obj.should_receive(:outputs) { [output] }
        obj.should_receive(:resource_summaries) { [resource_summary] }
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[])
           .with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }

      client.instance_variable_get(:@post_processing)
           .should_receive(:run_ssh_command)
           .with({"host"=>"<%= Key \"PublicIp\" %>", "user"=>"ec2-user", "request_pty"=>true}, "      ls\n", {"PublicIp"=>"127-0-0-1"})
           .and_return(["file1\nfile2\n", "", 0])

      client.instance_variable_get(:@post_processing)
            .should_receive(:print_command).with('ssh_command')

      client.instance_variable_get(:@post_processing)
            .should_receive(:print_command_result)
            .with("file1\nfile2\n", "", 0)

      client.instance_variable_get(:@post_processing)
            .should_receive(:save_command_results)
            .with([{'ssh_command' => {'ExitStatus' => 0, 'StdOut' => "file1\nfile2\n", 'StdErr' => ""}}])
    end
  end

  it 'update a stack from Ruby template and run command (specifies timing)' do
    template = <<-TEMPLATE
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

  Region do
    Value do
      Ref "AWS::Region"
    end
  end
end

_post do
  command_a do
    after :update
    command <<-EOS
      echo <%= Key "AZ" %>
      echo <%= Key "Region" %>
    EOS
  end
  command_b do
    after :create, :update
    command <<-EOS
      echo <%= Key "Region" %>
      echo <%= Key "AZ" %>
    EOS
  end
end
    TEMPLATE

    run_client(:update, :arguments => ['MyStack'], :template => template) do |client, cf|
      json = eval_template(template).to_json
      client.should_receive(:print_event_log).once
      client.should_receive(:create_event_log).once

      output1 = make_double('output') do |obj|
        obj.should_receive(:key) { 'AZ' }
        obj.should_receive(:value) { 'ap-northeast-1b' }
      end

      output2 = make_double('output') do |obj|
        obj.should_receive(:key) { 'Region' }
        obj.should_receive(:value) { 'ap-northeast-1' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        obj.should_receive(:[]).with(:resource_status) { 'UPDATE_COMPLETE' }
        obj.should_receive(:[]).with(:resource_status_reason) { nil }
        obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:update).with(:template => json)
        obj.should_receive(:status).and_return(
            'UPDATE_COMPLETE', 'UPDATE_COMPLETE', 'UPDATE_COMPLETE')
        obj.should_receive(:outputs) { [output1, output2] }
        obj.should_receive(:resource_summaries) { [resource_summary] }
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[])
           .with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }


      process_status1 = make_double('process_status1') {|obj| obj.should_receive(:to_i).and_return(0) }
      process_status2 = make_double('process_status2') {|obj| obj.should_receive(:to_i).and_return(0) }

      client.instance_variable_get(:@post_processing)
           .should_receive(:run_shell_command)
           .with("      echo <%= Key \"AZ\" %>\n      echo <%= Key \"Region\" %>\n", {"AZ"=>"ap-northeast-1b", "Region"=>"ap-northeast-1"})
           .and_return(["ap-northeast-1b\nap-northeast-1\n", "", process_status1])
      client.instance_variable_get(:@post_processing)
           .should_receive(:run_shell_command)
           .with("      echo <%= Key \"Region\" %>\n      echo <%= Key \"AZ\" %>\n", {"AZ"=>"ap-northeast-1b", "Region"=>"ap-northeast-1"})
           .and_return(["ap-northeast-1\nap-northeast-1b\n", "", process_status2])

      client.instance_variable_get(:@post_processing)
            .should_receive(:print_command).with('command_a')
      client.instance_variable_get(:@post_processing)
            .should_receive(:print_command).with('command_b')

      client.instance_variable_get(:@post_processing)
            .should_receive(:print_command_result)
            .with("ap-northeast-1b\nap-northeast-1\n", "", process_status1)
      client.instance_variable_get(:@post_processing)
            .should_receive(:print_command_result)
            .with("ap-northeast-1\nap-northeast-1b\n", "", process_status2)

      client.instance_variable_get(:@post_processing)
            .should_receive(:save_command_results)
            .with([{'command_a' => {'ExitStatus' => 0, 'StdOut' => "ap-northeast-1b\nap-northeast-1\n", 'StdErr' => ""}},
                   {'command_b' => {'ExitStatus' => 0, 'StdOut' => "ap-northeast-1\nap-northeast-1b\n", 'StdErr' => ""}}])
    end
  end

  it 'update a stack from Ruby template and run command (create timing)' do
    template = <<-TEMPLATE
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

  Region do
    Value do
      Ref "AWS::Region"
    end
  end
end

_post do
  command_a do
    after :create
    command <<-EOS
      echo <%= Key "AZ" %>
      echo <%= Key "Region" %>
    EOS
  end
  command_b do
    after :create
    command <<-EOS
      echo <%= Key "Region" %>
      echo <%= Key "AZ" %>
    EOS
  end
end
    TEMPLATE

    run_client(:update, :arguments => ['MyStack'], :template => template) do |client, cf|
      json = eval_template(template).to_json
      client.should_receive(:print_event_log).once
      client.should_receive(:create_event_log).once

      output1 = make_double('output') do |obj|
        obj.should_receive(:key) { 'AZ' }
        obj.should_receive(:value) { 'ap-northeast-1b' }
      end

      output2 = make_double('output') do |obj|
        obj.should_receive(:key) { 'Region' }
        obj.should_receive(:value) { 'ap-northeast-1' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        obj.should_receive(:[]).with(:resource_status) { 'UPDATE_COMPLETE' }
        obj.should_receive(:[]).with(:resource_status_reason) { nil }
        obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:update).with(:template => json)
        obj.should_receive(:status).and_return(
            'UPDATE_COMPLETE', 'UPDATE_COMPLETE', 'UPDATE_COMPLETE')
        obj.should_receive(:outputs) { [output1, output2] }
        obj.should_receive(:resource_summaries) { [resource_summary] }
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[])
           .with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }

      process_status1 = double('process_status1')
      process_status2 = double('process_status2')

      Open3.should_not_receive(:capture3)

      client.instance_variable_get(:@post_processing)
            .should_not_receive(:print_command_result)

      client.instance_variable_get(:@post_processing)
            .should_not_receive(:save_command_results)
    end
  end

  it 'update a stack from Ruby template with parameters' do
    template = <<-EOS
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
    EOS

    run_client(:update, :arguments => ['MyStack'], :template => template, :options => {:parameters => {'InstanceType'=>'m1.large'}}) do |client, cf|
      json = eval_template(template).to_json
      client.should_receive(:print_event_log).once
      client.should_receive(:create_event_log).once

      output = make_double('output') do |obj|
        obj.should_receive(:key) { 'AZ' }
        obj.should_receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        obj.should_receive(:[]).with(:resource_status) { 'UPDATE_COMPLETE' }
        obj.should_receive(:[]).with(:resource_status_reason) { nil }
        obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:update).with(:template => json, :parameters=>{"InstanceType"=>"m1.large"})
        obj.should_receive(:status).and_return(
            'UPDATE_COMPLETE', 'UPDATE_COMPLETE', 'UPDATE_COMPLETE')
        obj.should_receive(:outputs) { [output] }
        obj.should_receive(:resource_summaries) { [resource_summary] }
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[])
           .with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }
    end
  end

  it 'update a stack from Ruby template with invalid stack name' do
    template = <<-EOS
Resources do
  myEC2Instance do
    Type "AWS::EC2::Instance"
    Properties do
      ImageId "ami-XXXXXXXX"
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

    expect {
      run_client(:update, :arguments => ['0MyStack'], :template => template)
    }.to raise_error("1 validation error detected: Value '0MyStack' at 'stackName' failed to satisfy constraint: Member must satisfy regular expression pattern: [a-zA-Z][-a-zA-Z0-9]*")
  end

  it 'update a stack from Ruby template with encrypted parameters' do
    template = <<-EOS
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
    EOS

    run_client(:update, :arguments => ['MyStack'], :template => template, :options => {:parameters => {'InstanceType'=>'m1.large'}, :encrypt_parameters => ['Password']}) do |client, cf|
      json = eval_template(template, :add_encryption_password => true).to_json
      client.should_receive(:print_event_log).once
      client.should_receive(:create_event_log).once

      output = make_double('output') do |obj|
        obj.should_receive(:key) { 'AZ' }
        obj.should_receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        obj.should_receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        obj.should_receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        obj.should_receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        obj.should_receive(:[]).with(:resource_status) { 'UPDATE_COMPLETE' }
        obj.should_receive(:[]).with(:resource_status_reason) { nil }
        obj.should_receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:update).with(:template => json, :parameters=>{"InstanceType"=>"m1.large", "EncryptionPassword"=>"KioqKioqKioqKioqKioqKg=="})
        obj.should_receive(:status).and_return(
            'UPDATE_COMPLETE', 'UPDATE_COMPLETE', 'UPDATE_COMPLETE')
        obj.should_receive(:outputs) { [output] }
        obj.should_receive(:resource_summaries) { [resource_summary] }
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[])
           .with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }
    end
  end
end
