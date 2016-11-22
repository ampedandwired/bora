require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { BoraCli.new }
  let(:bora_config) { default_config }

  describe "#status" do
    context "stack does not exist" do
      let(:stack) { setup_stack("web-prod", status: :not_created) }

      it 'indicates that the stack does not exist' do
        expect(stack).to receive(:status)
        output = bora.run(bora_config, "status", "web-prod")
        expect(output).to include(Bora::Cfn::StackStatus::DOES_NOT_EXIST_MESSAGE)
      end
    end

    context "stack exists" do
      let(:stack) { setup_stack("web-prod", status: :create_complete) }

      it 'indicates that the stack exists' do
        expect(stack).to receive(:status)
        output = bora.run(bora_config, "status", "web-prod")
        expect(output).to include("web-prod", "CREATE_COMPLETE")
      end
    end
  end

end
