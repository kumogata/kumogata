describe 'Kumogata::Client#show_outputs' do
  it 'show outputs' do

    outputs = run_client(:show_outputs, :arguments => ['MyStack']) do |client, cf|
      output = make_double('output') do |obj|
        expect(obj).to receive(:key) { 'AZ' }
        expect(obj).to receive(:value) { 'ap-northeast-1a' }
      end

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:status) { 'CREATE_COMPLETE' }
        expect(obj).to receive(:outputs) { [output] }
      end

      stacks = make_double('stacks') do |obj|
        expect(obj).to receive(:[]).with('MyStack') { stack }
      end

      expect(cf).to receive(:stacks) { stacks }
    end

    expect(outputs).to eq((<<-EOS).chomp)
{
  "AZ": "ap-northeast-1a"
}
    EOS
  end
end
