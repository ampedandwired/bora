require 'helper/spec_helper'

shared_examples 'bora#show_current' do
  describe "#show_current" do
    context "stack does not exist" do
      before { @stack = setup_stack("web-prod", status: :not_created) }

      it "indicates that the stack does not exist" do
        expect(@stack).to receive(:template).and_return(nil)
        output = bora.run(@config, "show_current", "web-prod")
        expect(output).to include(Bora::Stack::STACK_DOES_NOT_EXIST_MESSAGE % "web-prod")
      end
    end

    context "stack exists" do
      before { @stack = setup_stack("web-prod", status: :create_complete) }

      it "shows the current template contents" do
        template = '{"template": "body"}'
        expect(@stack).to receive(:template).and_return(template)
        output = bora.run(@config, "show_current", "web-prod")
        expect(output).to include(template)
      end
    end
  end
end
