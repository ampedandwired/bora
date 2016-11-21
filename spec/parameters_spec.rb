require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { BoraCli.new }
  before { @config = default_config }

  describe "#parameters" do
    context "stack does not exist" do
      before { @stack = setup_stack("web-prod", status: :not_created) }

      it "indicates that the stack does not exist" do
        expect(@stack).to receive(:parameters).and_return(nil)
        output = bora.run(@config, "parameters", "web-prod")
        expect(output).to include(Bora::Stack::STACK_DOES_NOT_EXIST_MESSAGE % "web-prod")
      end
    end

    context "stack exists" do
      before { @stack = setup_stack("web-prod", status: :create_complete) }

      it "prints the parameter detail" do
        parameters = [
          {
            parameter_key: "URL",
            parameter_value: "http://example.com"
          },
          {
            parameter_key: "UserId",
            parameter_value: "joe"
          }
        ]

        bora_parameters = setup_parameters(@stack, parameters)
        expect(@stack).to receive(:parameters).and_return(bora_parameters)
        parameter = bora.run(@config, "parameters", "web-prod")
        parameters.map(&:values).flatten.each { |v| expect(parameter).to include(v.to_s) }
      end

      it "indicates there is nothing to show if there are no parameters" do
        expect(@stack).to receive(:parameters).and_return([])
        parameter = bora.run(@config, "parameters", "web-prod")
        expect(parameter).to include(Bora::Stack::STACK_PARAMETERS_DO_NOT_EXIST_MESSAGE % "web-prod")
      end
    end
  end
end
