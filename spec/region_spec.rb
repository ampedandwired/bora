require "helper/spec_helper"

describe BoraCli do
  let(:bora) { described_class.new }
  before do
    @stack = setup_stack("web-prod")
    allow(@stack).to receive(:create)
  end

  it "uses the region specified in the global config" do
    expect(Bora::Cfn::Stack).to receive(:new).with("web-prod", "xx-yyyy-2").and_return(@stack)
    config = bora_config
    config['default_region'] = "xx-yyyy-2"
    output = bora.run(config, "apply", "web-prod")
  end

  it "uses the region specified in the template config" do
    expect(Bora::Cfn::Stack).to receive(:new).with("web-prod", "xx-yyyy-2").and_return(@stack)
    config = bora_config
    config['templates']['web']['default_region'] = "xx-yyyy-2"
    output = bora.run(config, "apply", "web-prod")
  end

  it "uses the region specified in the stack config" do
    expect(Bora::Cfn::Stack).to receive(:new).with("web-prod", "xx-yyyy-2").and_return(@stack)
    config = bora_config
    config['templates']['web']['stacks']['prod']['default_region'] = "xx-yyyy-2"
    output = bora.run(config, "apply", "web-prod")
  end

  def bora_config
    {
      "templates" => {
        "web" => {
          "template_file" => "web_template.json",
          "stacks" => {
            "prod" => {}
          }
        }
      }
    }
  end
end
