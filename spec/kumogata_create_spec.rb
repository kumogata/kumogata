describe 'Kumogata::Client#create' do
  it 'create a stack from Ruby template' do
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

    run_client(:create, :template => template) do |client, cf|
      template = eval_template(template, :update_deletion_policy => true)
      json = JSON.pretty_generate(template)
      expect(client).to receive(:print_event_log).twice
      expect(client).to receive(:create_event_log).once

      output = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'AZ' }
        expect(obj).to receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        expect(obj).to receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        expect(obj).to receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        expect(obj).to receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        expect(obj).to receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:[]).with(:resource_status_reason) { nil }
        expect(obj).to receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:status).and_return(
            'CREATE_COMPLETE', 'CREATE_COMPLETE',
            'DELETE_COMPLETE', 'DELETE_COMPLETE', 'DELETE_COMPLETE')
        expect(obj).to receive(:outputs) { [output] }
        expect(obj).to receive(:resource_summaries) { [resource_summary] }
        expect(obj).to receive(:delete)
      end

      stacks = make_double('stacks') do |obj|
        expect(obj).to receive(:create)
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {}) { stack }
        expect(obj).to receive(:[])
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX') { stack }
      end

      expect(cf).to receive(:stacks).twice { stacks }
    end
  end

  it 'create a stack from Ruby template (detach)' do
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

    out = run_client(:create, :template => template, :options => {:detach => true}) do |client, cf|
      template = eval_template(template, :update_deletion_policy => true)
      json = JSON.pretty_generate(template)
      expect(client).not_to receive(:print_event_log)
      expect(client).not_to receive(:create_event_log)

      stack = make_double('stack') do |obj|
        expect(obj).not_to receive(:status)
        expect(obj).not_to receive(:outputs)
        expect(obj).not_to receive(:resource_summaries)
        expect(obj).not_to receive(:delete)
      end

      stacks = make_double('stacks') do |obj|
        expect(obj).to receive(:create)
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {}) { stack }
        expect(obj).not_to receive(:[])
      end

      expect(cf).to receive(:stacks).once { stacks }
    end

    expect(out).to be_nil
  end

  it 'create a stack from Ruby template and run command' do
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

    run_client(:create, :template => template) do |client, cf|
      template = eval_template(template, :update_deletion_policy => true)
      json = JSON.pretty_generate(template)
      expect(client).to receive(:print_event_log).twice
      expect(client).to receive(:create_event_log).once

      output1 = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'AZ' }
        expect(obj).to receive(:value) { 'ap-northeast-1b' }
      end

      output2 = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'Region' }
        expect(obj).to receive(:value) { 'ap-northeast-1' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        expect(obj).to receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        expect(obj).to receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        expect(obj).to receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        expect(obj).to receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:[]).with(:resource_status_reason) { nil }
        expect(obj).to receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:status).and_return(
            'CREATE_COMPLETE', 'CREATE_COMPLETE',
            'DELETE_COMPLETE', 'DELETE_COMPLETE', 'DELETE_COMPLETE')
        expect(obj).to receive(:outputs) { [output1, output2] }
        expect(obj).to receive(:resource_summaries) { [resource_summary] }
        expect(obj).to receive(:delete)
      end

      stacks = make_double('stacks') do |obj|
        expect(obj).to receive(:create)
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {}) { stack }
        expect(obj).to receive(:[])
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX') { stack }
      end

      expect(cf).to receive(:stacks).twice { stacks }

      process_status1 = make_double('process_status1') {|obj| expect(obj).to receive(:to_i).and_return(0) }
      process_status2 = make_double('process_status2') {|obj| expect(obj).to receive(:to_i).and_return(0) }

      expect(client.instance_variable_get(:@post_processing))
           .to receive(:run_shell_command)
           .with("      echo <%= Key \"AZ\" %>\n      echo <%= Key \"Region\" %>\n", {"AZ"=>"ap-northeast-1b", "Region"=>"ap-northeast-1"})
           .and_return(["ap-northeast-1b\nap-northeast-1\n", "", process_status1])
      expect(client.instance_variable_get(:@post_processing))
           .to receive(:run_shell_command)
           .with("      echo <%= Key \"Region\" %>\n      echo <%= Key \"AZ\" %>\n", {"AZ"=>"ap-northeast-1b", "Region"=>"ap-northeast-1"})
           .and_return(["ap-northeast-1\nap-northeast-1b\n", "", process_status2])

      expect(client.instance_variable_get(:@post_processing))
            .to receive(:print_command).with('command:a')
      expect(client.instance_variable_get(:@post_processing))
            .to receive(:print_command).with('command:b')

      expect(client.instance_variable_get(:@post_processing))
            .to receive(:print_command_result)
            .with("ap-northeast-1b\nap-northeast-1\n", "", process_status1)
      expect(client.instance_variable_get(:@post_processing))
            .to receive(:print_command_result)
            .with("ap-northeast-1\nap-northeast-1b\n", "", process_status2)

      expect(client.instance_variable_get(:@post_processing))
            .to receive(:save_command_results)
            .with([{'command:a' => {'ExitStatus' => 0, 'StdOut' => "ap-northeast-1b\nap-northeast-1\n", 'StdErr' => ""}},
                   {'command:b' => {'ExitStatus' => 0, 'StdOut' => "ap-northeast-1\nap-northeast-1b\n", 'StdErr' => ""}}])
    end
  end

  it 'create a stack from Ruby template and run ssh command' do
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

    run_client(:create, :template => template) do |client, cf|
      template = eval_template(template, :update_deletion_policy => true)
      json = JSON.pretty_generate(template)
      expect(client).to receive(:print_event_log).twice
      expect(client).to receive(:create_event_log).once

      output = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'PublicIp' }
        expect(obj).to receive(:value) { '127.0.0.1' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        expect(obj).to receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        expect(obj).to receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        expect(obj).to receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        expect(obj).to receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:[]).with(:resource_status_reason) { nil }
        expect(obj).to receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:status).and_return(
            'CREATE_COMPLETE', 'CREATE_COMPLETE',
            'DELETE_COMPLETE', 'DELETE_COMPLETE', 'DELETE_COMPLETE')
        expect(obj).to receive(:outputs) { [output] }
        expect(obj).to receive(:resource_summaries) { [resource_summary] }
        expect(obj).to receive(:delete)
      end

      stacks = make_double('stacks') do |obj|
        expect(obj).to receive(:create)
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {}) { stack }
        expect(obj).to receive(:[])
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX') { stack }
      end

      expect(cf).to receive(:stacks).twice { stacks }

      expect(client.instance_variable_get(:@post_processing))
           .to receive(:run_ssh_command)
           .with({"host"=>"<%= Key \"PublicIp\" %>", "user"=>"ec2-user", "request_pty"=>true}, "      ls\n", {"PublicIp"=>"127.0.0.1"})
           .and_return(["file1\nfile2\n", "", 0])

      expect(client.instance_variable_get(:@post_processing))
            .to receive(:print_command).with('ssh:command')

      expect(client.instance_variable_get(:@post_processing))
            .to receive(:print_command_result)
            .with("file1\nfile2\n", "", 0)

      expect(client.instance_variable_get(:@post_processing))
            .to receive(:save_command_results)
            .with([{'ssh:command' => {'ExitStatus' => 0, 'StdOut' => "file1\nfile2\n", 'StdErr' => ""}}])
    end
  end

  it 'create a stack from Ruby template and run ssh command (modify outputs)' do
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
  outputs['MyOutput'] = 100
end

_post do
  ssh_command do
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

    run_client(:create, :template => template) do |client, cf|
      template = eval_template(template, :update_deletion_policy => true)
      json = JSON.pretty_generate(template)
      expect(client).to receive(:print_event_log).twice
      expect(client).to receive(:create_event_log).once

      output = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'PublicIp' }
        expect(obj).to receive(:value) { '127.0.0.1' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        expect(obj).to receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        expect(obj).to receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        expect(obj).to receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        expect(obj).to receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:[]).with(:resource_status_reason) { nil }
        expect(obj).to receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:status).and_return(
            'CREATE_COMPLETE', 'CREATE_COMPLETE',
            'DELETE_COMPLETE', 'DELETE_COMPLETE', 'DELETE_COMPLETE')
        expect(obj).to receive(:outputs) { [output] }
        expect(obj).to receive(:resource_summaries) { [resource_summary] }
        expect(obj).to receive(:delete)
      end

      stacks = make_double('stacks') do |obj|
        expect(obj).to receive(:create)
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {}) { stack }
        expect(obj).to receive(:[])
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX') { stack }
      end

      expect(cf).to receive(:stacks).twice { stacks }

      expect(client.instance_variable_get(:@post_processing))
           .to receive(:run_ssh_command)
           .with({"host"=>"<%= Key \"PublicIp\" %>", "user"=>"ec2-user", "request_pty"=>true}, "      ls\n", {"PublicIp"=>"127.0.0.1", "MyOutput"=>100})
           .and_return(["file1\nfile2\n", "", 0])

      expect(client.instance_variable_get(:@post_processing))
            .to receive(:print_command).with('ssh:command')

      expect(client.instance_variable_get(:@post_processing))
            .to receive(:print_command_result)
            .with("file1\nfile2\n", "", 0)

      expect(client.instance_variable_get(:@post_processing))
            .to receive(:save_command_results)
            .with([{'ssh:command' => {'ExitStatus' => 0, 'StdOut' => "file1\nfile2\n", 'StdErr' => ""}}])
    end
  end

  it 'create a stack from Ruby template and run command (specifies timing)' do
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
    after :create, :update
    command <<-EOS
      echo <%= Key "Region" %>
      echo <%= Key "AZ" %>
    EOS
  end
end
    TEMPLATE

    run_client(:create, :template => template) do |client, cf|
      template = eval_template(template, :update_deletion_policy => true)
      json = JSON.pretty_generate(template)
      expect(client).to receive(:print_event_log).twice
      expect(client).to receive(:create_event_log).once

      output1 = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'AZ' }
        expect(obj).to receive(:value) { 'ap-northeast-1b' }
      end

      output2 = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'Region' }
        expect(obj).to receive(:value) { 'ap-northeast-1' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        expect(obj).to receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        expect(obj).to receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        expect(obj).to receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        expect(obj).to receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:[]).with(:resource_status_reason) { nil }
        expect(obj).to receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:status).and_return(
            'CREATE_COMPLETE', 'CREATE_COMPLETE',
            'DELETE_COMPLETE', 'DELETE_COMPLETE', 'DELETE_COMPLETE')
        expect(obj).to receive(:outputs) { [output1, output2] }
        expect(obj).to receive(:resource_summaries) { [resource_summary] }
        expect(obj).to receive(:delete)
      end

      stacks = make_double('stacks') do |obj|
        expect(obj).to receive(:create)
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {}) { stack }
        expect(obj).to receive(:[])
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX') { stack }
      end

      expect(cf).to receive(:stacks).twice { stacks }

      process_status1 = make_double('process_status1') {|obj| expect(obj).to receive(:to_i).and_return(0) }
      process_status2 = make_double('process_status2') {|obj| expect(obj).to receive(:to_i).and_return(0) }

      expect(client.instance_variable_get(:@post_processing))
           .to receive(:run_shell_command)
           .with("      echo <%= Key \"AZ\" %>\n      echo <%= Key \"Region\" %>\n", {"AZ"=>"ap-northeast-1b", "Region"=>"ap-northeast-1"})
           .and_return(["ap-northeast-1b\nap-northeast-1\n", "", process_status1])
      expect(client.instance_variable_get(:@post_processing))
           .to receive(:run_shell_command)
           .with("      echo <%= Key \"Region\" %>\n      echo <%= Key \"AZ\" %>\n", {"AZ"=>"ap-northeast-1b", "Region"=>"ap-northeast-1"})
           .and_return(["ap-northeast-1\nap-northeast-1b\n", "", process_status2])

      expect(client.instance_variable_get(:@post_processing))
            .to receive(:print_command).with('command:a')
      expect(client.instance_variable_get(:@post_processing))
            .to receive(:print_command).with('command:b')

      expect(client.instance_variable_get(:@post_processing))
            .to receive(:print_command_result)
            .with("ap-northeast-1b\nap-northeast-1\n", "", process_status1)
      expect(client.instance_variable_get(:@post_processing))
            .to receive(:print_command_result)
            .with("ap-northeast-1\nap-northeast-1b\n", "", process_status2)

      expect(client.instance_variable_get(:@post_processing))
            .to receive(:save_command_results)
            .with([{'command:a' => {'ExitStatus' => 0, 'StdOut' => "ap-northeast-1b\nap-northeast-1\n", 'StdErr' => ""}},
                   {'command:b' => {'ExitStatus' => 0, 'StdOut' => "ap-northeast-1\nap-northeast-1b\n", 'StdErr' => ""}}])
    end
  end

  it 'create a stack from Ruby template and run command (update timing)' do
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
    after :update
    command <<-EOS
      echo <%= Key "Region" %>
      echo <%= Key "AZ" %>
    EOS
  end
end
    TEMPLATE

    run_client(:create, :template => template) do |client, cf|
      template = eval_template(template, :update_deletion_policy => true)
      json = JSON.pretty_generate(template)
      expect(client).to receive(:print_event_log).twice
      expect(client).to receive(:create_event_log).once

      output1 = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'AZ' }
        expect(obj).to receive(:value) { 'ap-northeast-1b' }
      end

      output2 = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'Region' }
        expect(obj).to receive(:value) { 'ap-northeast-1' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        expect(obj).to receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        expect(obj).to receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        expect(obj).to receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        expect(obj).to receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:[]).with(:resource_status_reason) { nil }
        expect(obj).to receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:status).and_return(
            'CREATE_COMPLETE', 'CREATE_COMPLETE',
            'DELETE_COMPLETE', 'DELETE_COMPLETE', 'DELETE_COMPLETE')
        expect(obj).to receive(:outputs) { [output1, output2] }
        expect(obj).to receive(:resource_summaries) { [resource_summary] }
        expect(obj).to receive(:delete)
      end

      stacks = make_double('stacks') do |obj|
        expect(obj).to receive(:create)
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {}) { stack }
        expect(obj).to receive(:[])
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX') { stack }
      end

      expect(cf).to receive(:stacks).twice { stacks }

      expect(Open3).not_to receive(:capture3)

      expect(client.instance_variable_get(:@post_processing))
            .not_to receive(:print_command_result)

      expect(client.instance_variable_get(:@post_processing))
            .not_to receive(:save_command_results)
    end
  end

  it 'create a stack from Ruby template (include DeletionPolicy)' do
    template = <<-EOS
Resources do
  myEC2Instance do
    Type "AWS::EC2::Instance"
    Properties do
      ImageId "ami-XXXXXXXX"
      InstanceType "t1.micro"
    end
    DeletionPolicy "Delete"
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

    run_client(:create, :template => template) do |client, cf|
      template = eval_template(template, :update_deletion_policy => true)
      expect(template['Resources']['myEC2Instance']['DeletionPolicy']).to eq('Delete')
      json = JSON.pretty_generate(template)
      expect(client).to receive(:print_event_log).twice
      expect(client).to receive(:create_event_log).once

      output = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'AZ' }
        expect(obj).to receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        expect(obj).to receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        expect(obj).to receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        expect(obj).to receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        expect(obj).to receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:[]).with(:resource_status_reason) { nil }
        expect(obj).to receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:status).and_return(
            'CREATE_COMPLETE', 'CREATE_COMPLETE',
            'DELETE_COMPLETE', 'DELETE_COMPLETE', 'DELETE_COMPLETE')
        expect(obj).to receive(:outputs) { [output] }
        expect(obj).to receive(:resource_summaries) { [resource_summary] }
        expect(obj).to receive(:delete)
      end

      stacks = make_double('stacks') do |obj|
        expect(obj).to receive(:create)
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {}) { stack }
        expect(obj).to receive(:[])
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX') { stack }
      end

      expect(cf).to receive(:stacks).twice { stacks }
    end
  end

  it 'create a stack from Ruby template with parameters' do
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

    run_client(:create, :template => template, :options => {:parameters => {'InstanceType'=>'m1.large'}}) do |client, cf|
      template = eval_template(template, :update_deletion_policy => true)
      json = JSON.pretty_generate(template)
      expect(client).to receive(:print_event_log).twice
      expect(client).to receive(:create_event_log).once

      output = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'AZ' }
        expect(obj).to receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        expect(obj).to receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        expect(obj).to receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        expect(obj).to receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        expect(obj).to receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:[]).with(:resource_status_reason) { nil }
        expect(obj).to receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:status).and_return(
            'CREATE_COMPLETE', 'CREATE_COMPLETE',
            'DELETE_COMPLETE', 'DELETE_COMPLETE', 'DELETE_COMPLETE')
        expect(obj).to receive(:outputs) { [output] }
        expect(obj).to receive(:resource_summaries) { [resource_summary] }
        expect(obj).to receive(:delete)
      end

      stacks = make_double('stacks') do |obj|
        expect(obj).to receive(:create)
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {:parameters=>{"InstanceType"=>"m1.large"}}) { stack }
        expect(obj).to receive(:[])
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX') { stack }
      end

      expect(cf).to receive(:stacks).twice { stacks }
    end
  end

  it 'create a stack from Ruby template with stack name' do
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

    run_client(:create, :arguments => ['MyStack'], :template => template) do |client, cf|
      template = eval_template(template)
      json = JSON.pretty_generate(template)
      expect(client).to receive(:print_event_log).once

      output = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'AZ' }
        expect(obj).to receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        expect(obj).to receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        expect(obj).to receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        expect(obj).to receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        expect(obj).to receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:[]).with(:resource_status_reason) { nil }
        expect(obj).to receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:status).and_return(
            'CREATE_COMPLETE',
            'CREATE_COMPLETE')
        expect(obj).to receive(:outputs) { [output] }
        expect(obj).to receive(:resource_summaries) { [resource_summary] }
      end

      stacks = make_double('status') do |obj|
        expect(obj).to receive(:create)
           .with('MyStack', json, {}) { stack }
      end

      expect(cf).to receive(:stacks) { stacks }
    end
  end

  it 'create a stack from Ruby template with deletion policy retain' do
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

    run_client(:create, :arguments => ['MyStack'], :template => template, :options => {:deletion_policy_retain => true}) do |client, cf|
      template = eval_template(template, :update_deletion_policy => true)
      json = JSON.pretty_generate(template)
      expect(client).to receive(:print_event_log).once

      output = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'AZ' }
        expect(obj).to receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        expect(obj).to receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        expect(obj).to receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        expect(obj).to receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        expect(obj).to receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:[]).with(:resource_status_reason) { nil }
        expect(obj).to receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:status).and_return(
            'CREATE_COMPLETE',
            'CREATE_COMPLETE')
        expect(obj).to receive(:outputs) { [output] }
        expect(obj).to receive(:resource_summaries) { [resource_summary] }
      end

      stacks = make_double('status') do |obj|
        expect(obj).to receive(:create)
           .with('MyStack', json, {}) { stack }
      end

      expect(cf).to receive(:stacks) { stacks }
    end
  end

  it 'create a stack from Ruby template with invalid stack name' do
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

    expect {
      run_client(:create, :arguments => ['0MyStack'], :template => template)
    }.to raise_error("1 validation error detected: Value '0MyStack' at 'stackName' failed to satisfy constraint: Member must satisfy regular expression pattern: [a-zA-Z][-a-zA-Z0-9]*")
  end

  it 'create a stack from Ruby template with encrypted parameters' do
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

    run_client(:create, :template => template, :options => {:parameters => {'InstanceType'=>'m1.large'}, :encrypt_parameters => ['Password']}) do |client, cf|
      template = eval_template(template, :update_deletion_policy => true, :add_encryption_password => true)
      json = JSON.pretty_generate(template)
      expect(client).to receive(:print_event_log).twice
      expect(client).to receive(:create_event_log).once

      output = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'AZ' }
        expect(obj).to receive(:value) { 'ap-northeast-1b' }
      end

      resource_summary = make_double('resource_summary') do |obj|
        expect(obj).to receive(:[]).with(:logical_resource_id) { 'myEC2Instance' }
        expect(obj).to receive(:[]).with(:physical_resource_id) { 'i-XXXXXXXX' }
        expect(obj).to receive(:[]).with(:resource_type) { 'AWS::EC2::Instance' }
        expect(obj).to receive(:[]).with(:resource_status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:[]).with(:resource_status_reason) { nil }
        expect(obj).to receive(:[]).with(:last_updated_timestamp) { '2014-03-02 04:35:12 UTC' }
      end

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:status).and_return(
            'CREATE_COMPLETE', 'CREATE_COMPLETE',
            'DELETE_COMPLETE', 'DELETE_COMPLETE', 'DELETE_COMPLETE')
        expect(obj).to receive(:outputs) { [output] }
        expect(obj).to receive(:resource_summaries) { [resource_summary] }
        expect(obj).to receive(:delete)
      end

      stacks = make_double('stacks') do |obj|
        expect(obj).to receive(:create)
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', json, {:parameters=>{"InstanceType"=>"m1.large", "EncryptionPassword"=>"KioqKioqKioqKioqKioqKg=="}}) { stack }
        expect(obj).to receive(:[])
           .with('kumogata-user-host-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX') { stack }
      end

      expect(cf).to receive(:stacks).twice { stacks }
    end
  end
end
