require 'helper/spec_helper'

shared_examples 'bora#status' do
  describe "#status" do
    context "stack does not exist" do
      before { @stack = setup_stack("web-prod", status: :not_created) }

      it 'indicates that the stack does not exist' do
        output = bora.run(@config, "status", "web-prod")
        expect(output).to include(Bora::Cfn::StackStatus::DOES_NOT_EXIST_MESSAGE)
      end
    end

    context "stack exists" do
      before { @stack = setup_stack("web-prod", status: :create_complete) }

      it 'indicates that the stack exists' do
        output = bora.run(@config, "status", "web-prod")
        expect(output).to include("web-prod")
        expect(output).to include("CREATE_COMPLETE")
      end
    end
  end

end
