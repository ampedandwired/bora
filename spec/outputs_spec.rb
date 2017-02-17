require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { BoraCli.new }
  let(:bora_config) { default_config }

  describe '#outputs' do
    context 'stack does not exist' do
      let(:stack) { setup_stack('web-prod', status: :not_created) }

      it 'indicates that the stack does not exist' do
        expect(stack).to receive(:outputs).and_return(nil)
        output = bora.run(bora_config, 'outputs', 'web-prod')
        expect(output).to include(Bora::Stack::STACK_DOES_NOT_EXIST_MESSAGE % 'web-prod')
      end
    end

    context 'stack exists' do
      let(:stack) { setup_stack('web-prod', status: :create_complete) }

      it 'prints the output detail' do
        outputs = [
          {
            output_key: 'URL',
            output_value: 'http://example.com',
            description: 'Description1'
          },
          {
            output_key: 'UserId',
            output_value: 'joe'
          }
        ]

        bora_outputs = setup_outputs(@stack, outputs)
        expect(stack).to receive(:outputs).and_return(bora_outputs)
        output = bora.run(bora_config, 'outputs', 'web-prod')
        outputs.map(&:values).flatten.each { |v| expect(output).to include(v.to_s) }
      end

      it 'indicates there is nothing to show if there are no outputs' do
        expect(stack).to receive(:outputs).and_return([])
        output = bora.run(bora_config, 'outputs', 'web-prod')
        expect(output).to include(Bora::Stack::STACK_OUTPUTS_DO_NOT_EXIST_MESSAGE % 'web-prod')
      end
    end
  end
end
