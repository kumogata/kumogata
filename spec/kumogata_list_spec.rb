describe 'Kumogata::Client#list' do
  it 'list stacks' do
    json = run_client(:list) do |client, cf|
      stack1 = make_double('stack1') do |obj|
        obj.should_receive(:name) { 'stack1' }
        obj.should_receive(:creation_time) { '2014-03-02 16:17:18 UTC' }
        obj.should_receive(:status) { 'CREATE_COMPLETE' }
        obj.should_receive(:description) { nil }
      end

      stack2 = make_double('stack2') do |obj|
        obj.should_receive(:name) { 'stack2' }
        obj.should_receive(:creation_time) { '2014-03-02 16:17:19 UTC' }
        obj.should_receive(:status) { 'CREATE_COMPLETE' }
        obj.should_receive(:description) { nil }
      end

      cf.should_receive(:stacks) { [stack1, stack2] }
    end

    expect(json).to eq((<<-EOS).chomp)
[
  {
    "StackName": "stack1",
    "CreationTime": "2014-03-02 16:17:18 UTC",
    "StackStatus": "CREATE_COMPLETE",
    "Description": null
  },
  {
    "StackName": "stack2",
    "CreationTime": "2014-03-02 16:17:19 UTC",
    "StackStatus": "CREATE_COMPLETE",
    "Description": null
  }
]
    EOS
  end

  it 'list a specified stack' do
    json = run_client(:list, :arguments => ['stack1']) do |client, cf|
      stack1 = make_double('stack1') do |obj|
        obj.should_receive(:name).twice { 'stack1' }
        obj.should_receive(:creation_time) { '2014-03-02 16:17:18 UTC' }
        obj.should_receive(:status) { 'CREATE_COMPLETE' }
        obj.should_receive(:description) { nil }
      end

      stack2 = make_double('stack2') do |obj|
        obj.should_receive(:name) { 'stack2' }
      end

      cf.should_receive(:stacks) { [stack1, stack2] }
    end

    expect(json).to eq((<<-EOS).chomp)
[
  {
    "StackName": "stack1",
    "CreationTime": "2014-03-02 16:17:18 UTC",
    "StackStatus": "CREATE_COMPLETE",
    "Description": null
  }
]
    EOS
  end

end
