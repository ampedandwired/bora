require 'uri'
require 'helper/spec_helper'
require 'bora/resolver/credstash'

describe Bora::Resolver::Credstash do
  let(:resolver) { described_class.new }

  it "returns the value from credstash" do
    expect(resolver).to receive(:`).with("credstash get foo").and_return("bar")
    expect(resolver.resolve(URI("credstash:///foo"))).to eq("bar")
  end

  it "passes key context from query params" do
    expect(resolver).to receive(:`).with("credstash get foo k1=v1 k2=v2").and_return("bar")
    expect(resolver.resolve(URI("credstash:///foo?k1=v1&k2=v2"))).to eq("bar")
  end

  it "raises an exception if the parameter is invalid" do
    expect{resolver.resolve(URI("credstash://"))}.to raise_exception(Bora::Resolver::Credstash::InvalidParameter)
    expect{resolver.resolve(URI("credstash:///"))}.to raise_exception(Bora::Resolver::Credstash::InvalidParameter)
    expect{resolver.resolve(URI("credstash://?foo=bar"))}.to raise_exception(Bora::Resolver::Credstash::InvalidParameter)
  end
end
