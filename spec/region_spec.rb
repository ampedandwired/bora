require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { BoraCli.new }
  let(:stack) { setup_stack('web-prod', status: :not_created) }
  let(:bora_config) { default_config(default_region: 'xx-yyyy-1') }
  before { allow(stack).to receive(:create) }

  it 'uses the region specified in the global config' do
    expect(Bora::Cfn::Stack).to receive(:new).with('web-prod', 'xx-yyyy-1').and_return(stack)
    output = bora.run(bora_config, 'apply', 'web-prod')
  end

  it 'uses the region specified in the template config, which overrides global config' do
    expect(Bora::Cfn::Stack).to receive(:new).with('web-prod', 'xx-yyyy-2').and_return(stack)
    config = bora_config
    config.templates.web.default_region = 'xx-yyyy-2'
    output = bora.run(config, 'apply', 'web-prod')
  end

  it 'uses the region specified in the stack config, which overrides template and global config' do
    expect(Bora::Cfn::Stack).to receive(:new).with('web-prod', 'xx-yyyy-3').and_return(stack)
    config = bora_config
    config.templates.web.default_region = 'xx-yyyy-2'
    config.templates.web.stacks.prod.default_region = 'xx-yyyy-3'
    output = bora.run(config, 'apply', 'web-prod')
  end

  it 'uses the region specified on the command line, which overrides all other config' do
    expect(Bora::Cfn::Stack).to receive(:new).with('web-prod', 'xx-yyyy-4').and_return(stack)
    config = bora_config
    config.templates.web.default_region = 'xx-yyyy-2'
    config.templates.web.stacks.prod.default_region = 'xx-yyyy-3'
    output = bora.run(config, 'apply', 'web-prod', '--region', 'xx-yyyy-4')
  end
end
