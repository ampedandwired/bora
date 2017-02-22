require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { BoraCli.new }
  let(:bora_config) { default_config }

  describe '#show_current' do
    context 'stack does not exist' do
      let(:stack) { setup_stack('web-prod', status: :not_created) }

      it 'indicates that the stack does not exist' do
        expect(stack).to receive(:template).and_return(nil)
        output = bora.run(bora_config, 'show_current', 'web-prod')
        expect(output).to include(Bora::Stack::STACK_DOES_NOT_EXIST_MESSAGE % 'web-prod')
      end
    end

    context 'stack exists' do
      let(:stack) { setup_stack('web-prod', status: :create_complete) }

      it 'shows the current template contents' do
        template = '{"template": "body"}'
        expect(stack).to receive(:template).and_return(template)
        output = bora.run(bora_config, 'show_current', 'web-prod')
        expect(output).to include('"template": "body"')
      end
    end
  end
end
