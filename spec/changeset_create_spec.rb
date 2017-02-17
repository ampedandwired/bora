require 'time'
require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { BoraCli.new }
  let(:stack) { setup_stack('web-prod', status: :created) }
  let(:bora_config) { default_config }

  it 'creates a change set' do
    change_set_name = 'test-change-set'
    change_set = setup_create_change_set(stack, change_set_name, status: 'CREATE_COMPLETE',
                                                                 status_reason: 'Finished',
                                                                 execution_status: 'AVAILABLE',
                                                                 description: 'My change set',
                                                                 creation_time: Time.parse('2016-07-21 15:01:00'),
                                                                 changes: [
                                                                   {
                                                                     resource_change: {
                                                                       action: 'Modify',
                                                                       resource_type: 'AWS::EC2::SecurityGroup',
                                                                       logical_resource_id: 'MySG'
                                                                     }
                                                                   }
                                                                 ])

    expect(stack).to receive(:create_change_set).with(change_set_name, anything).and_return(change_set)
    output = bora.run(bora_config, 'changeset', 'create', 'web-prod', change_set_name)
    expect(output).to include('CREATE_COMPLETE', 'AVAILABLE', '2016-07-21 15:01:00')
    expect(output).to include('Modify', 'AWS::EC2::SecurityGroup', 'MySG')
  end
end
