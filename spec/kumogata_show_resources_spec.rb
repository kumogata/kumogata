describe 'Kumogata::Client#show_resources' do
  it 'show resources' do

    resources = run_client(:show_resources, :arguments => ['MyStack']) do |client, cf|
      stack = make_double('stack') do |obj|
        obj.should_receive(:status) { 'CREATE_COMPLETE' }
        obj.should_receive(:resource_summaries).and_return([
          {
            :logical_resource_id    => 'myEC2Instance',
            :physical_resource_id   => 'i-XXXXXXXX',
            :resource_type          => 'AWS::EC2::Instance',
            :resource_status        => 'CREATE_COMPLETE',
            :resource_status_reason => nil,
            :last_updated_timestamp => '2014-03-03 04:04:40 UTC',
          }
        ])
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[]).with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }
    end

    expect(resources).to eq((<<-EOS).chomp)
[
  {
    "LogicalResourceId": "myEC2Instance",
    "PhysicalResourceId": "i-XXXXXXXX",
    "ResourceType": "AWS::EC2::Instance",
    "ResourceStatus": "CREATE_COMPLETE",
    "ResourceStatusReason": null,
    "LastUpdatedTimestamp": "2014-03-03 04:04:40 UTC"
  }
]
    EOS
  end
end
