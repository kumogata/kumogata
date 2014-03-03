describe 'Kumogata::Client#outputs' do
  it 'show outputs' do

    outputs = run_client(:show_outputs, :arguments => ['MyStack']) do |client, cf|
      output = make_double('output') do |obj|
        obj.should_receive(:key) { 'AZ' }
        obj.should_receive(:value) { 'ap-northeast-1a' }
      end

      stack = make_double('stack') do |obj|
        obj.should_receive(:status) { 'CREATE_COMPLETE' }
        obj.should_receive(:outputs) { [output] }
      end

      stacks = make_double('stacks') do |obj|
        obj.should_receive(:[]).with('MyStack') { stack }
      end

      cf.should_receive(:stacks) { stacks }
    end

    expect(outputs).to eq((<<-EOS).chomp)
{
  "AZ": "ap-northeast-1a"
}
    EOS
  end
end
