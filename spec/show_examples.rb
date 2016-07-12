require 'helper/spec_helper'

shared_examples 'bora#show' do
  describe "#show" do
    before { @stack = setup_stack("web-prod", status: :create_complete) }

    it "shows the template contents" do
      expect(@stack).to receive(:new_template).with({template_url: "web_template.json"}).and_return('{"template": "body"}')
      output = bora.run(@config, "show", "web-prod")
      expect(output).to include('{"template": "body"}')
    end

  end
end
