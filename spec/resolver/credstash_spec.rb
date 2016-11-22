require 'uri'
require 'helper/spec_helper'
require 'bora/resolver/credstash'

describe Bora::Resolver::Credstash do
  let(:stack) do
    s = double(Bora::Stack)
    allow(s).to receive(:region).and_return(DEFAULT_REGION)
    s
  end

  let(:resolver) { Bora::Resolver::Credstash.new(stack) }

  before do
    client = double(Aws::CloudFormation::Client)
    allow(Aws::CloudFormation::Client).to receive(:new).and_return(client)
  end

  it "returns the value from credstash" do
    expect(resolver).to receive(:`).with("credstash --region #{DEFAULT_REGION} get foo").and_return(" bar \n")
    expect(resolver.resolve(URI("credstash:///foo"))).to eq(" bar")
  end

  it "passes key context from query params" do
    expect(resolver).to receive(:`).with("credstash --region #{DEFAULT_REGION} get foo k1=v1 k2=v2").and_return("bar")
    expect(resolver.resolve(URI("credstash:///foo?k1=v1&k2=v2"))).to eq("bar")
  end


  it "uses the stack's region if specified" do
    expect(stack).to receive(:region).and_return("xx-yyyy-1")
    expect(resolver).to receive(:`).with("credstash --region xx-yyyy-1 get foo").and_return("bar")
    expect(resolver.resolve(URI("credstash:///foo"))).to eq("bar")
  end

  it "uses the uri's region if specified, which overrides the stack's region" do
    expect(stack).to_not receive(:region)
    expect(resolver).to receive(:`).with("credstash --region aa-bbbb-1 get foo").and_return("bar")
    expect(resolver.resolve(URI("credstash://aa-bbbb-1/foo"))).to eq("bar")
  end

  it "raises an exception if the parameter is invalid" do
    expect{resolver.resolve(URI("credstash://"))}.to raise_exception(Bora::Resolver::Credstash::InvalidParameter)
    expect{resolver.resolve(URI("credstash:///"))}.to raise_exception(Bora::Resolver::Credstash::InvalidParameter)
    expect{resolver.resolve(URI("credstash://?foo=bar"))}.to raise_exception(Bora::Resolver::Credstash::InvalidParameter)
  end

end
