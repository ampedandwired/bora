require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { BoraCli.new }
  before { @config = default_config }

  describe "#show" do
    before { @stack = setup_stack("web-prod", status: :create_complete) }

    it "shows the template contents" do
      output = bora.run(@config, "show", "web-prod")
      expected_template = JSON.pretty_generate(JSON.parse(File.read(@config["templates"]["web"]["template_file"])))
      expect(output).to include(expected_template)
    end

  end
end
