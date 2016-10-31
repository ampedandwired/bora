require 'helper/spec_helper'

shared_examples 'bora#validate' do
  describe "#validate" do
    before { @stack = setup_stack("web-prod", status: :create_complete) }

    it "indicates that the templates is OK if it validates successfully" do
      expect(@stack).to receive(:validate).with(hash_including(:template_body)).and_return(true)
      output = bora.run(@config, "validate", "web-prod")
      expect(output).to include(Bora::Stack::STACK_VALIDATE_SUCCESS_MESSAGE % "web-prod")
    end

    it "prints an error if it fails validation" do
      expect(@stack).to receive(:validate).with(hash_including(:template_body)).and_raise("Not valid")
      output = bora.run(@config, "validate", "web-prod")
      expect(output).to include("Not valid")
    end

  end
end
