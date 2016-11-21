require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { BoraCli.new }
  before { @config = default_config }

  describe "#apply" do
    context "stack does not exist" do
      before do
        @stack = setup_stack("web-prod", status: :not_created)
        @outputs = setup_outputs(@stack, [
          output_key: "output1",
          output_value: "value1",
          description: "desc1"
        ])
      end

      it "creates the stack" do
        expect(@stack).to receive(:create)
          .with(hash_including(:template_body))
          .and_return(true)
        output = bora.run(@config, "apply", "web-prod")
        expect(output).to include(Bora::Stack::STACK_ACTION_SUCCESS_MESSAGE % ["Create", "web-prod"])
        expect(output).to include("output1")
        expect(output).to include("value1")
        expect(output).to include("desc1")
      end
    end

    context "stack exists" do
      before { @stack = setup_stack("web-prod", status: :create_complete) }

      it "updates the stack if the template has changed" do
        expect(@stack).to receive(:update)
          .with(hash_including(:template_body))
          .and_return(true)
        output = bora.run(@config, "apply", "web-prod")
        expect(output).to include(Bora::Stack::STACK_ACTION_SUCCESS_MESSAGE % ["Update", "web-prod"])
      end

      it "indicates that there are no changes if the template is the same" do
        expect(@stack).to receive(:update)
          .with(hash_including(:template_body))
          .and_return(nil)
        output = bora.run(@config, "apply", "web-prod")
        expect(output).to include(Bora::Stack::STACK_ACTION_NOT_CHANGED_MESSAGE % ["Update", "web-prod"])
      end

      it "indicates there was an error if the update fails" do
        expect(@stack).to receive(:update)
          .with(hash_including(:template_body))
          .and_return(false)
        output = bora.run(@config, "apply", "web-prod")
        expect(output).to include(Bora::Stack::STACK_ACTION_FAILURE_MESSAGE % ["Update", "web-prod"])
      end
    end

  end
end
