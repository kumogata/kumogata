describe 'Kumogata::Client#list' do
  it 'list stacks' do
    json = run_client(:list) do |client, cf|
      stack1 = make_double('stack1') do |obj|
        expect(obj).to receive(:name) { 'stack1' }
        expect(obj).to receive(:creation_time) { '2014-03-02 16:17:18 UTC' }
        expect(obj).to receive(:status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:description) { nil }
      end

      stack2 = make_double('stack2') do |obj|
        expect(obj).to receive(:name) { 'stack2' }
        expect(obj).to receive(:creation_time) { '2014-03-02 16:17:19 UTC' }
        expect(obj).to receive(:status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:description) { nil }
      end

      expect(cf).to receive(:stacks) { [stack1, stack2] }
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
        expect(obj).to receive(:name).twice { 'stack1' }
        expect(obj).to receive(:creation_time) { '2014-03-02 16:17:18 UTC' }
        expect(obj).to receive(:status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:description) { nil }
      end

      stack2 = make_double('stack2') do |obj|
        expect(obj).to receive(:name) { 'stack2' }
      end

      expect(cf).to receive(:stacks) { [stack1, stack2] }
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
