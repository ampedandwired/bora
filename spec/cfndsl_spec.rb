require "helper/spec_helper"

describe BoraCli do
  EXPECTED_JSON = '{"AWSTemplateFormatVersion":"2010-09-09","Resources":{"EBApp":{"Properties":{"ApplicationName":"MyApp"},"Type":"AWS::ElasticBeanstalk::Application"}}}'

  let(:bora) { BoraCli.new }
  let(:stack) { setup_stack("web-prod", status: :not_created) }

  it "generates the template using cfndsl if the template is a .rb file" do
    expect(stack).to receive(:create)
      .with({ template_body: EXPECTED_JSON })
      .and_return(true)
    output = bora.run(bora_config, "apply", "web-prod")
  end

  it "generates pretty json if specified" do
    expect(stack).to receive(:create)
      .with({ template_body: JSON.pretty_generate(JSON.parse(EXPECTED_JSON)) })
      .and_return(true)
    output = bora.run(bora_config, "apply", "web-prod", "--pretty")
  end

  def bora_config
    config = default_config
    config.templates.web.template_file = File.join(__dir__, "fixtures/cfndsl_spec_template.rb")
    config
  end
end
