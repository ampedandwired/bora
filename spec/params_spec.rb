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
      .with(hash_including(
        :template_body,
        parameters: cfn_params(params)
      ))
      .and_return(true)

    output = bora.run(bora_config(params: params), "apply", "web-prod")
  end

  it "overrides parameters in the config with parameters passed on the command line" do
    params = { "foo" => "bar" }
    expected_params = { "foo" => "overridden" }
    expect(@stack).to receive(:create)
      .with(hash_including(
        :template_body,
        parameters: cfn_params(expected_params)
      ))
      .and_return(true)

    output = bora.run(bora_config(params: params), "apply", "web-prod", "--params", "foo=overridden")
  end

  it "passes no params to CloudFormation if params are empty" do
    expect(@stack).to receive(:create)
      .with(hash_including(:template_body))
      .and_return(true)

    output = bora.run(bora_config, "apply", "web-prod")
  end

  it "passes through cloudformation parameters from the stack config" do
    config = bora_config(stack_config: {"capabilities" => ["CAPABILITY_IAM"]})
    expect(@stack).to receive(:create)
      .with(hash_including(
        :template_body,
        "capabilities" => ["CAPABILITY_IAM"]
      ))
      .and_return(true)

    output = bora.run(config, "apply", "web-prod")
  end

  it "passes through cloudformation parameters from the template config" do
    config = bora_config(template_config: {"capabilities" => ["CAPABILITY_IAM"]})
    expect(@stack).to receive(:create)
      .with(hash_including(
        :template_body,
        "capabilities" => ["CAPABILITY_IAM"]
      ))
      .and_return(true)

    output = bora.run(config, "apply", "web-prod")
  end

  it "passes declared CloudFormation parameters through from the config when using cfndsl" do
    cfn_params = {"DbUsername" => "user_cloudformation_param"}
    bora_params = cfn_params.merge({"default_db_username" => "user_cfndsl_param"})
    expect(@stack).to receive(:create)
      .with({
        template_body: '{"AWSTemplateFormatVersion":"2010-09-09","Parameters":{"DbUsername":{"Type":"String","Default":"user_cfndsl_param"}}}',
        parameters: cfn_params(cfn_params)
      })
      .and_return(true)

    config = bora_config(template_file: File.join(__dir__, "fixtures/params_spec_template.rb"), params: bora_params)
    output = bora.run(config, "apply", "web-prod")
  end


  def bora_config(template_file: File.join(__dir__, "fixtures/web_template.json"), template_config: {}, stack_config: {}, params: {})
    config = {
      "templates" => {
        "web" => {
          "template_file" => template_file,
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
