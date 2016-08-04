require "helper/spec_helper"

describe Bora::ParameterResolverLoader do
  let(:loader) { described_class.new }

  it "loads the named parameter resolver" do
    expect(loader.load_resolver("cfn").to_s).to eq("Bora::Resolver::Cfn")
  end

  it "raises an exception if the resolver wasn't found" do
    expect{loader.load_resolver("invalid_resolver")}.to raise_exception(Bora::ParameterResolverLoader::ResolverNotFound)
  end
end
