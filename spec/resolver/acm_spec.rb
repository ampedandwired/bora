require 'uri'
require 'helper/spec_helper'
require 'bora/resolver/acm'

describe Bora::Resolver::Acm do
  let(:bora_stack) do
    s = double(Bora::Stack)
    allow(s).to receive(:region).and_return(DEFAULT_REGION)
    s
  end

  let(:resolver) { Bora::Resolver::Acm.new(bora_stack) }

  let(:acm_client) do
    client = double(Aws::ACM::Client)
    allow(Aws::ACM::Client).to receive(:new).with(region: DEFAULT_REGION).and_return(client)
    client
  end

  it 'returns a valid certificate for *.example.com' do
    expect(acm_client).to receive(:list_certificates)
      .with(list_certificates_request)
      .and_return(list_certificates_response)
    expect(resolver.resolve(URI('acm://*.example.com')))
      .to eq('arn:aws:acm:us-east-1:123456789:certificate/asdf-1234')
  end

  it 'returns a valid certificate for example.com' do
    expect(acm_client).to receive(:list_certificates)
      .with(list_certificates_request)
      .and_return(list_certificates_response)
    expect(resolver.resolve(URI('acm://example.com')))
      .to eq('arn:aws:acm:us-east-1:123456789:certificate/asdf-1235')
  end

  it 'raises an exception if no certificate is found' do
    expect(acm_client).to receive(:list_certificates).and_return(list_certificates_response)
    expect { resolver.resolve(URI('acm://example.invalid')) }.to raise_exception(Bora::Resolver::Acm::NoACM)
  end

  def list_certificates_request
    {
      certificate_statuses: ['ISSUED'],
      max_items: 10
    }
  end

  def list_certificates_response
    Hashie::Mash.new(
      certificate_summary_list: [
        {
          certificate_arn: 'arn:aws:acm:us-east-1:123456789:certificate/asdf-1234',
          domain_name: '*.example.com'
        },
        {
          certificate_arn: 'arn:aws:acm:us-east-1:123456789:certificate/asdf-1235',
          domain_name: 'example.com'
        },
        {
          certificate_arn: 'arn:aws:acm:us-east-1:123456789:certificate/asdf-1236',
          domain_name: 'test.example.com'
        }
      ]
    )
  end

  def empty_list_certificates_response
    Hashie::Mash.new(certificate_summary_list: [])
  end
end
