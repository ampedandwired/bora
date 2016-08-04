require 'uri'
require 'helper/spec_helper'
require 'bora/resolver/cfn'

describe Bora::Resolver::Cfn do
  let(:resolver) { described_class.new }

  context "when the stack exists" do
    before do
      @stack = setup_stack("web-prod", status: :create_complete)
      setup_outputs(@stack, [{
        output_key: "UserId",
        output_value: "joe"
      }])
    end

    it "retrieves the given output from the stack" do
      expect(resolver.resolve(URI("cfn://web-prod/outputs/UserId"))).to eq("joe")
    end

    it "raises an exception if the value does not exist" do
      expect{resolver.resolve(URI("cfn://web-prod/outputs/DoesNotExist"))}.to raise_exception(Bora::Resolver::Cfn::ValueNotFound)
    end

    it "raises an exception if the parameter is invalid" do
      expect{resolver.resolve(URI("cfn://web-prod/invalid/UserId"))}.to raise_exception(Bora::Resolver::Cfn::InvalidParameter)
      expect{resolver.resolve(URI("cfn://web-prod/UserId"))}.to raise_exception(Bora::Resolver::Cfn::InvalidParameter)
      expect{resolver.resolve(URI("cfn://web-prod"))}.to raise_exception(Bora::Resolver::Cfn::InvalidParameter)
      expect{resolver.resolve(URI("cfn://?stack=web-prod"))}.to raise_exception(Bora::Resolver::Cfn::InvalidParameter)
    end
  end

  context "when the stack exists" do
    before do
      @stack = setup_stack("web-prod", status: :not_created)
    end

    it "raises an exception" do
      expect{resolver.resolve(URI("cfn://web-prod/outputs/UserId"))}.to raise_exception(Bora::Resolver::Cfn::StackDoesNotExist)
    end
  end

end
