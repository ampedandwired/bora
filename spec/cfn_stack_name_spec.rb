require "helper/spec_helper"

describe BoraCli do
  let(:bora) { described_class.new }
  before do
    @stack = setup_stack("web-prod")
    allow(@stack).to receive(:create)
  end

  it "uses the cfn stack name specified in the stack config" do
    expect(Bora::Cfn::Stack).to receive(:new).with("my-web-prod-stack", DEFAULT_REGION).and_return(@stack)
    config = bora_config
    bora.run(config, "apply", "web-prod")
  end

  it "supports the deprecated 'stack_name' parameter" do
    expect(Bora::Cfn::Stack).to receive(:new).with("my-web-prod-stack", DEFAULT_REGION).and_return(@stack)
    config = bora_config("stack_name")
    output = bora.run(config, "apply", "web-prod")
    expect(output).to include("deprecated")
  end

  it "uses the cfn stack name specified on the command line, which overrides all other config" do
    expect(Bora::Cfn::Stack).to receive(:new).with("my-web-prod-stack-cli", DEFAULT_REGION).and_return(@stack)
    config = bora_config
    bora.run(config, "apply", "web-prod", "--cfn-stack-name", "my-web-prod-stack-cli")
  end

  def bora_config(cfn_stack_name_param = "cfn_stack_name")
    config = {
      "templates" => {
        "web" => {
          "template_file" => "web_template.json",
          "stacks" => {
            "prod" => {
              cfn_stack_name_param => "my-web-prod-stack"
            }
          }
        }
      }
    }
    setup_template(config, "web", {})
    config
  end
end
