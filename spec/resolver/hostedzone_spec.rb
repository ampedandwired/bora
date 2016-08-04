require 'ostruct'
require 'uri'
require 'aws-sdk'
require 'helper/spec_helper'
require 'bora/resolver/hostedzone'

describe Bora::Resolver::Hostedzone do
  let(:resolver) { described_class.new }

  before do
    @route53 = double
    response = OpenStruct.new(
      hosted_zones: [
        OpenStruct.new(
          id: "1",
          name: "example.com",
          config: OpenStruct.new(
            private_zone: false
          )
        ),
        OpenStruct.new(
          id: "2",
          name: "example.com",
          config: OpenStruct.new(
            private_zone: true
          )
        ),
        OpenStruct.new(
          id: "3",
          name: "unique.com",
          config: OpenStruct.new(
            private_zone: true
          )
        )
      ]
    )

    allow(Aws::Route53::Client).to receive(:new).and_return(@route53)
    allow(@route53).to receive(:list_hosted_zones).and_return(response)
  end

  it "returns a single matching public hosted zone" do
    expect(resolver.resolve(URI("hostedzone:///unique.com"))).to eq("3")
  end

  it "matches on public/private zone types" do
    expect(resolver.resolve(URI("hostedzone:///example.com/public"))).to eq("1")
    expect(resolver.resolve(URI("hostedzone:///example.com/private"))).to eq("2")
  end

  it "allows the region to be provided" do
    expect(Aws::Route53::Client).to receive(:new).with({region: "ap-southeast-2"}).and_return(@route53)
    resolver.resolve(URI("hostedzone://ap-southeast-2/unique.com"))
  end

  it "raises an exception if there were multiple matching zones" do
    expect{resolver.resolve(URI("hostedzone:///example.com"))}.to raise_exception(Bora::Resolver::Hostedzone::MultipleMatchesError)
  end

  it "raises an exception if there was no zone found" do
    expect{resolver.resolve(URI("hostedzone:///notthere.com"))}.to raise_exception(Bora::Resolver::Hostedzone::NotFoundError)
  end

  it "raises an exception if the parameter is invalid" do
    expect{resolver.resolve(URI("hostedzone:///"))}.to raise_exception(Bora::Resolver::Hostedzone::InvalidParameterError)
    expect{resolver.resolve(URI("hostedzone:///?foo=bar"))}.to raise_exception(Bora::Resolver::Hostedzone::InvalidParameterError)
  end
end
