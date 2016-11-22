require "helper/spec_helper"

describe BoraCli do
  BORA_CONFIG_STACK_NAME = "my-web-prod-stack"

  let(:bora) { BoraCli.new }
  let(:stack) { setup_stack("web-prod", status: :not_created) }
  before { allow(stack).to receive(:create) }

  it "uses the cfn stack name specified in the stack config" do
    expect(Bora::Cfn::Stack).to receive(:new).with(BORA_CONFIG_STACK_NAME, anything).and_return(stack)
    bora.run(bora_config, "apply", "web-prod")
  end

  it "supports the deprecated 'stack_name' parameter" do
    expect(Bora::Cfn::Stack).to receive(:new).with(BORA_CONFIG_STACK_NAME, anything).and_return(stack)
    config = bora_config("stack_name")
    output = bora.run(config, "apply", "web-prod")
    expect(output).to include("deprecated")
  end

  it "uses the cfn stack name specified on the command line, which overrides all other config" do
    expect(Bora::Cfn::Stack).to receive(:new).with("my-web-prod-stack-cli", anything).and_return(stack)
    bora.run(bora_config, "apply", "web-prod", "--cfn-stack-name", "my-web-prod-stack-cli")
  end

  def bora_config(cfn_stack_name_param = "cfn_stack_name")
    config = default_config
    config.templates.web.stacks.prod[cfn_stack_name_param] = BORA_CONFIG_STACK_NAME
    config
  end
end
