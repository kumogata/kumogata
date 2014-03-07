describe 'Kumogata::Client#show_events' do
  it 'show events' do

    resources = run_client(:show_events, :arguments => ['MyStack']) do |client, cf|
      event = make_double('event') do |obj|
        obj.should_receive(:event_id) { "f45e6070-a4f7-11e3-9326-5088487c4896" }
        obj.should_receive(:logical_resource_id) { "kumogata-f11118a4-a4f7-11e3-8183-98fe943e66ca" }
        obj.should_receive(:physical_resource_id) { "arn:aws:cloudformation:ap-northeast-1:822997939312:stack/kumogata-f11118a4-a4f7-11e3-8183-98fe943e66ca/f1381a30-a4f7-11e3-a340-506cf9a1c096" }
        obj.should_receive(:resource_properties) { nil }
        obj.should_receive(:resource_status) { "CREATE_FAILED" }
        obj.should_receive(:resource_status_reason) { "The following resource(s) failed to create: [myEC2Instance]. " }
        obj.should_receive(:resource_type) { "AWS::CloudFormation::Stack" }
        obj.should_receive(:stack_id) { "arn:aws:cloudformation:ap-northeast-1:822997939312:stack/kumogata-f11118a4-a4f7-11e3-8183-98fe943e66ca/f1381a30-a4f7-11e3-a340-506cf9a1c096" }
        obj.should_receive(:stack_name) { "kumogata-f11118a4-a4f7-11e3-8183-98fe943e66ca" }
        obj.should_receive(:timestamp) { "2014-03-06 06:24:21 UTC" }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:status) { 'CREATE_COMPLETE' }
        obj.should_receive(:events).and_return([event])
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[]).with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }
    end

    expect(resources).to eq((<<-EOS).chomp)
[
  {
    "EventId": "f45e6070-a4f7-11e3-9326-5088487c4896",
    "LogicalResourceId": "kumogata-f11118a4-a4f7-11e3-8183-98fe943e66ca",
    "PhysicalResourceId": "arn:aws:cloudformation:ap-northeast-1:822997939312:stack/kumogata-f11118a4-a4f7-11e3-8183-98fe943e66ca/f1381a30-a4f7-11e3-a340-506cf9a1c096",
    "ResourceProperties": null,
    "ResourceStatus": "CREATE_FAILED",
    "ResourceStatusReason": "The following resource(s) failed to create: [myEC2Instance]. ",
    "ResourceType": "AWS::CloudFormation::Stack",
    "StackId": "arn:aws:cloudformation:ap-northeast-1:822997939312:stack/kumogata-f11118a4-a4f7-11e3-8183-98fe943e66ca/f1381a30-a4f7-11e3-a340-506cf9a1c096",
    "StackName": "kumogata-f11118a4-a4f7-11e3-8183-98fe943e66ca",
    "Timestamp": "2014-03-06 06:24:21 UTC"
  }
]
    EOS
  end
end
