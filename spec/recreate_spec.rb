require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { BoraCli.new }
  before { @config = default_config }

  describe '#recreate' do
    context 'stack does not exist' do
      before do
        @stack = setup_stack('web-prod', status: :not_created)
      end

      it 'creates the stack' do
        expect(@stack).to receive(:recreate)
          .with(hash_including(:template_body))
          .and_return(true)
        output = bora.run(@config, 'recreate', 'web-prod')
        expect(output).to include(Bora::Stack::STACK_ACTION_SUCCESS_MESSAGE % ['Recreate', 'web-prod'])
      end
    end

    context 'stack exists' do
      before { @stack = setup_stack('web-prod', status: :create_complete) }

      it 'recreates the stack' do
        expect(@stack).to receive(:recreate)
          .with(hash_including(:template_body))
          .and_return(true)
        output = bora.run(@config, 'recreate', 'web-prod')
        expect(output).to include(Bora::Stack::STACK_ACTION_SUCCESS_MESSAGE % ['Recreate', 'web-prod'])
      end

      it 'indicates that there are no changes if the template is the same' do
        expect(@stack).to receive(:recreate)
          .with(hash_including(:template_body))
          .and_return(nil)
        output = bora.run(@config, 'recreate', 'web-prod')
        expect(output).to include(Bora::Stack::STACK_ACTION_NOT_CHANGED_MESSAGE % ['Recreate', 'web-prod'])
      end

      it 'indicates there was an error if the recreation fails' do
        expect(@stack).to receive(:recreate)
          .with(hash_including(:template_body))
          .and_return(false)
        output = bora.run(@config, 'recreate', 'web-prod', expect_exception: true)
        expect(output).to include(Bora::Stack::STACK_ACTION_FAILURE_MESSAGE % ['Recreate', 'web-prod'])
      end
    end
  end
end
