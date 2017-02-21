require 'uri'
require 'helper/spec_helper'
require 'bora/resolver/cfn'

describe Bora::Resolver::Cfn do
  let(:bora_stack) do
    s = double(Bora::Stack)
    allow(s).to receive(:region).and_return(DEFAULT_REGION)
    s
  end

  let(:resolver) { Bora::Resolver::Cfn.new(bora_stack) }

  context 'when the stack exists' do
    before do
      @stack = setup_stack(
        'web-prod',
        status: :create_complete,
        outputs: [
          {
            output_key: 'UserId',
            output_value: 'joe'
          }
        ]
      )
    end

    it 'retrieves the given output from the stack' do
      expect(resolver.resolve(URI('cfn://web-prod/outputs/UserId'))).to eq('joe')
    end

    it 'uses the region from the stack when specified' do
      expect(bora_stack).to receive(:region).and_return('xx-yyyy-1')
      expect(Bora::Cfn::Stack).to receive(:new).with('web-prod', 'xx-yyyy-1').and_return(@stack)
      expect(resolver.resolve(URI('cfn://web-prod/outputs/UserId'))).to eq('joe')
    end

    it 'uses the region from the uri when specified, which overrides the region of the stack' do
      expect(bora_stack).to_not receive(:region)
      expect(Bora::Cfn::Stack).to receive(:new).with('web-prod', 'aa-bbbb-1').and_return(@stack)
      expect(resolver.resolve(URI('cfn://web-prod.aa-bbbb-1/outputs/UserId'))).to eq('joe')
    end

    it 'raises an exception if the value does not exist' do
      expect { resolver.resolve(URI('cfn://web-prod/outputs/DoesNotExist')) }.to raise_exception(Bora::Resolver::Cfn::ValueNotFound)
    end

    it 'raises an exception if the parameter is invalid' do
      expect { resolver.resolve(URI('cfn://web-prod/invalid/UserId')) }.to raise_exception(Bora::Resolver::Cfn::InvalidParameter)
      expect { resolver.resolve(URI('cfn://web-prod/UserId')) }.to raise_exception(Bora::Resolver::Cfn::InvalidParameter)
      expect { resolver.resolve(URI('cfn://web-prod')) }.to raise_exception(Bora::Resolver::Cfn::InvalidParameter)
      expect { resolver.resolve(URI('cfn://?stack=web-prod')) }.to raise_exception(Bora::Resolver::Cfn::InvalidParameter)
    end
  end

  context 'when the stack exists' do
    before do
      @stack = setup_stack('web-prod', status: :not_created)
    end

    it 'raises an exception' do
      expect { resolver.resolve(URI('cfn://web-prod/outputs/UserId')) }.to raise_exception(Bora::Resolver::Cfn::StackDoesNotExist)
    end
  end
end
