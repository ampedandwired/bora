require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { BoraCli.new }
  before { @config = default_config }

  describe "#delete" do
    context "stack does not exist" do
      before { @stack = setup_stack("web-prod", status: :not_created) }

      it "indicates that the stack was deleted" do
        expect(@stack).to receive(:delete).and_return(true)
        output = bora.run(@config, "delete", "web-prod")
        expect(output).to include(Bora::Stack::STACK_ACTION_SUCCESS_MESSAGE % ["Delete", "web-prod"])
      end
    end

    context "stack exists" do
      before { @stack = setup_stack("web-prod", status: :create_complete) }

      it "deletes the stack" do
        expect(@stack).to receive(:delete).and_return(true)
        output = bora.run(@config, "delete", "web-prod")
        expect(output).to include(Bora::Stack::STACK_ACTION_SUCCESS_MESSAGE % ["Delete", "web-prod"])
      end

      it "indicates there was an error if deleting the stack failed" do
        expect(@stack).to receive(:delete).and_return(false)
        output = bora.run(@config, "delete", "web-prod")
        expect(output).to include(Bora::Stack::STACK_ACTION_FAILURE_MESSAGE % ["Delete", "web-prod"])
      end
    end
  end
end
