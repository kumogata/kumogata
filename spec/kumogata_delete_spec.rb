describe 'Kumogata::Client#delete' do
  it 'update a stack from Ruby template' do
    run_client(:delete, :arguments => ['MyStack'], :options => {:force => true}) do |client, cf|
      expect(client).to receive(:print_event_log).once
      expect(client).to receive(:create_event_log).once

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:delete).with(no_args())
        expect(obj).to receive(:status).and_return(
            'DELETE_COMPLETE', 'DELETE_COMPLETE', 'DELETE_COMPLETE')
      end

      stacks = make_double('stacks') do |obj|
        expect(obj).to receive(:[])
           .with('MyStack') { stack }
      end

      expect(cf).to receive(:stacks) { stacks }
    end
  end

  it 'update a stack from Ruby template (detach)' do
    out = run_client(:delete, :arguments => ['MyStack'], :options => {:force => true, :detach => true}) do |client, cf|
      expect(client).not_to receive(:print_event_log)
      expect(client).to receive(:create_event_log).once

      stack = make_double('stack') do |obj|
        expect(obj).to receive(:delete).with(no_args())
        expect(obj).to receive(:status).once
      end

      stacks = make_double('stacks') do |obj|
        expect(obj).to receive(:[])
           .with('MyStack') { stack }
      end

      expect(cf).to receive(:stacks) { stacks }
    end

    expect(out).to be_nil
  end
end
