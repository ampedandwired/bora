require 'helper/spec_helper'

shared_examples 'bora#diff' do
  describe "#diff" do
    context "stack does not exist" do
      before do
        @config["templates"]["web"]["stacks"]["prod"]["params"] = {"Port" => "80"}
        @stack = setup_stack("web-prod", status: :not_created)
        setup_parameters(@stack, [])
      end

      it "shows the whole template as being new" do
        current_template = ""
        new_template = "aaa\nbbb\nccc"
        expect(@stack).to receive(:template).and_return(current_template)
        expect(@stack).to receive(:new_template).and_return(new_template)
        output = bora.run(@config, "diff", "web-prod")
        expect(output).to include("+Port - 80")
        expect(output).to include("+aaa")
        expect(output).to include("+bbb")
        expect(output).to include("+ccc")
      end
    end

    context "stack exists and template has changed" do
      before do
        @config["templates"]["web"]["stacks"]["prod"]["params"] = {"Port" => "80", "Timeout" => "60"}
        @stack = setup_stack("web-prod", status: :create_complete)
        setup_parameters(@stack, [{parameter_key: "Port", parameter_value: "22"}])
      end

      it "shows the difference between the current and new templates" do
        current_template = "aaa\nccc"
        new_template = "aaa\nbbb\nccc"
        expect(@stack).to receive(:template).and_return(current_template)
        expect(@stack).to receive(:new_template).and_return(new_template)
        output = bora.run(@config, "diff", "web-prod")
        expect(output).to include("Parameters")
        expect(output).to include("-Port - 22")
        expect(output).to include("+Port - 80")
        expect(output).to include("+Timeout - 60")
        expect(output).not_to include("+aaa")
        expect(output).to include("+bbb")
        expect(output).not_to include("+ccc")
      end
    end

    context "stack exists but template is the same" do
      before do
        @config["templates"]["web"]["stacks"]["prod"]["params"] = {"Port" => "22"}
        @stack = setup_stack("web-prod", status: :create_complete)
        setup_parameters(@stack, [{parameter_key: "Port", parameter_value: "22"}])
      end

      it "Indicates if the template has not changed" do
        current_template = "aaa\nccc"
        new_template = "aaa\nccc"
        expect(@stack).to receive(:template).and_return(current_template)
        expect(@stack).to receive(:new_template).and_return(new_template)
        output = bora.run(@config, "diff", "web-prod")
        expect(output).to include("Parameters")
        expect(output).to include(Bora::Stack::STACK_DIFF_PARAMETERS_UNCHANGED_MESSAGE)
        expect(output).to include(Bora::Stack::STACK_DIFF_TEMPLATE_UNCHANGED_MESSAGE)
      end
    end

    context "stack exists without parameters" do
      before do
        @stack = setup_stack("web-prod", status: :create_complete)
        setup_parameters(@stack, [])
      end

      it "does not show the parameters section in the diff" do
        current_template = "aaa\nccc"
        new_template = "aaa\nccc"
        expect(@stack).to receive(:template).and_return(current_template)
        expect(@stack).to receive(:new_template).and_return(new_template)
        output = bora.run(@config, "diff", "web-prod")
        expect(output).not_to include("Parameters")
      end
    end
  end
end
