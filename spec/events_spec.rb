require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { BoraCli.new }
  let(:bora_config) { default_config }

  describe '#events' do
    context 'stack does not exist' do
      let(:stack) { setup_stack('web-prod', status: :not_created) }

      it 'indicates that the stack does not exist' do
        expect(stack).to receive(:events).and_return(nil)
        output = bora.run(bora_config, 'events', 'web-prod')
        expect(output).to include(Bora::Stack::STACK_DOES_NOT_EXIST_MESSAGE % 'web-prod')
      end
    end

    context 'stack exists' do
      let(:stack) { setup_stack('web-prod', status: :create_complete) }

      it 'prints event detail' do
        events = [
          {
            timestamp: Time.new('2016-07-21 15:01:00'),
            logical_resource_id: '1234',
            resource_type: 'ApiGateway',
            resource_status: 'CREATE_COMPLETE',
            resource_status_reason: 'reason1'
          },
          {
            timestamp: Time.new('2016-07-21 15:00:00'),
            logical_resource_id: '5678',
            resource_type: 'LambdaFunction',
            resource_status: 'CREATE_FAILED'
          }
        ]

        setup_events(stack, events)
        output = bora.run(bora_config, 'events', 'web-prod')
        events.map(&:values).flatten.each { |v| expect(output).to include(v.to_s) }
      end

      it 'indicates there is nothing to show if there are no events' do
        expect(stack).to receive(:events).and_return([])
        output = bora.run(bora_config, 'events', 'web-prod')
        expect(output).to include(Bora::Stack::STACK_EVENTS_DO_NOT_EXIST_MESSAGE % 'web-prod')
      end
    end
  end
end
