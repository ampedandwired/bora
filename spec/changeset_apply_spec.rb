require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { BoraCli.new }
  let(:stack) { setup_stack('web-prod') }
  let(:bora_config) { default_config }

  it 'applies the given change set' do
    change_set_name = 'test-change-set'
    expect(stack).to receive(:execute_change_set).with(change_set_name).and_return(true)
    output = bora.run(bora_config, 'changeset', 'apply', 'web-prod', change_set_name)
    expect(output).to include(Bora::Stack::STACK_ACTION_SUCCESS_MESSAGE % ["Execute change set '#{change_set_name}'", 'web-prod'])
  end
end
