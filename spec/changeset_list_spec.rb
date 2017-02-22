require 'time'
require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { described_class.new }
  let(:stack) { setup_stack('web-prod') }
  let(:bora_config) { default_config }

  it 'creates a change set' do
    change_sets = setup_change_sets(
      stack,
      [
        {
          change_set_name: 'cs1',
          status: 'CREATE_COMPLETE',
          status_reason: 'Finished',
          execution_status: 'AVAILABLE',
          description: 'My change set',
          creation_time: Time.parse('2016-07-21 15:01:00')
        },
        {
          change_set_name: 'cs2',
          status: 'CREATE_FAILED',
          status_reason: 'Error',
          execution_status: 'UNAVAILABLE',
          creation_time: Time.parse('2016-07-20 15:01:00')
        }
      ]
    )

    expect(stack).to receive(:list_change_sets).and_return(change_sets)
    output = bora.run(bora_config, 'changeset', 'list', 'web-prod')
    expect(output).to include('cs1', 'CREATE_COMPLETE', 'AVAILABLE', 'Finished', '2016-07-21 15:01:00', 'My change set')
    expect(output).to include('cs2', 'CREATE_FAILED', 'Error')
  end
end
