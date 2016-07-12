require 'helper/spec_helper'

shared_examples 'bora#diff' do
  describe "#diff" do
    context "stack does not exist" do
      before { @stack = setup_stack("web-prod", status: :not_created) }

      it "shows the whole template as being new" do
        new_template = "aaa\nbbb\nccc"
        expect(@stack).to receive(:diff)
          .with({template_url: "web_template.json"})
          .and_return(Diffy::Diff.new("", new_template))
        output = bora.run(@config, "diff", "web-prod")
        expect(output).to include("+aaa")
        expect(output).to include("+bbb")
        expect(output).to include("+ccc")
      end
    end

    context "stack exists" do
      before { @stack = setup_stack("web-prod", status: :create_complete) }

      it "shows the difference between the current and new templates" do
        new_template = "aaa\nbbb\nccc"
        expect(@stack).to receive(:diff)
          .with({template_url: "web_template.json"})
          .and_return(Diffy::Diff.new("aaa\nccc", new_template))
        output = bora.run(@config, "diff", "web-prod")
        expect(output).not_to include("+aaa")
        expect(output).to include("+bbb")
        expect(output).not_to include("+ccc")
      end
    end
  end
end
