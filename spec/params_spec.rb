require "helper/spec_helper"

describe BoraCli do
  let(:bora) { described_class.new }
  before { @stack = setup_stack("web-prod", status: :not_created) }

  it "passes parameters to CloudFormation" do
    params = {
      "foo" => "bar",
      "baz" => 1,
      "bam" => true
    }

    expect(@stack).to receive(:create)
      .with({
        template_url: "web_template.json",
        parameters: cfn_params(params)
      })
      .and_return(true)

    output = bora.run(bora_config(params: params), "apply", "web-prod")
  end

  it "overrides parameters in the config with parameters passed on the command line" do
    params = { "foo" => "bar" }
    expect(@stack).to receive(:create)
      .with({
        template_url: "web_template.json",
        parameters: cfn_params(params)
      })
      .and_return(true)

    output = bora.run(bora_config(params: params), "apply", "web-prod", "--params", "foo=overridde")
  end

  it "passes no params to CloudFormation if params are empty" do
    expect(@stack).to receive(:create)
      .with({ template_url: "web_template.json" })
      .and_return(true)

    output = bora.run(bora_config, "apply", "web-prod")
  end

  it "passes through cloudformation parameters from the stack config" do
    config = bora_config(stack_config: {"capabilities" => ["CAPABILITY_IAM"]})
    expect(@stack).to receive(:create)
      .with({
        template_url: "web_template.json",
        "capabilities" => ["CAPABILITY_IAM"]
      })
      .and_return(true)

    output = bora.run(config, "apply", "web-prod")
  end

  it "passes through cloudformation parameters from the template config" do
    config = bora_config(template_config: {"capabilities" => ["CAPABILITY_IAM"]})
    expect(@stack).to receive(:create)
      .with({
        template_url: "web_template.json",
        "capabilities" => ["CAPABILITY_IAM"]
      })
      .and_return(true)

    output = bora.run(config, "apply", "web-prod")
  end


  def bora_config(template_config: {}, stack_config: {}, params: {})
    config = {
      "templates" => {
        "web" => {
          "template_file" => "web_template.json",
          "stacks" => {
            "prod" => {}
          }
        }
      }
    }

    config["templates"]["web"].merge!(template_config)
    config["templates"]["web"]["stacks"]["prod"].merge!(stack_config)
    config["templates"]["web"]["stacks"]["prod"]["params"] = params unless params.empty?
    config
  end

  def cfn_params(params)
    params.map { |k, v| { parameter_key: k, parameter_value: v } }
  end

end
