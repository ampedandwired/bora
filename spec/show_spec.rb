require 'helper/spec_helper'

describe BoraCli do
  let(:bora) { BoraCli.new }
  let(:bora_config) { default_config }

  describe '#show' do
    let(:stack) { setup_stack('web-prod', status: :create_complete) }

    it 'shows the template contents' do
      expected_template = JSON.pretty_generate(JSON.parse(File.read(bora_config.templates.web.template_file)))
      output = bora.run(bora_config, 'show', 'web-prod')
      expect(output).to include(expected_template)
    end
  end
end
