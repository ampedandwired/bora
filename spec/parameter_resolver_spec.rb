require 'uri'
require 'helper/spec_helper'

describe Bora::ParameterResolver do
  let(:parameter_resolver) { Bora::ParameterResolver.new(double) }
  let(:resolver) { double }

  before do
    loader = double(Bora::ParameterResolverLoader)
    resolver_class = double
    allow(Bora::ParameterResolverLoader).to receive(:new).and_return(loader)
    allow(loader).to receive(:load_resolver).and_return(resolver_class)
    allow(resolver_class).to receive(:new).and_return(resolver)
  end

  it 'resolves tokens in parameters' do
    params = {
      'key1' => 'value1',
      'key2' => '${foo://bar.baz/bing}'
    }

    expect(resolver).to receive(:resolve).with(URI('foo://bar.baz/bing')).and_return('foo')
    expect(parameter_resolver.resolve(params)).to eq('key1' => 'value1', 'key2' => 'foo')
  end

  it 'allows you to refer to another parameter' do
    params = { 'key1' => 'value1', 'key2' => '${key1}_foo' }
    expect(parameter_resolver.resolve(params)).to eq('key1' => 'value1', 'key2' => 'value1_foo')
  end

  it 'handles multiple levels of parameter indirection' do
    params = { 'aaa' => '${ccc}_baz', 'bbb' => '${ccc}_bing', 'ccc' => '${ddd}_foo_${foo://bar}', 'ddd' => 'dvalue' }
    expect(resolver).to receive(:resolve).once.with(URI('foo://bar')).and_return('bar')
    expect(parameter_resolver.resolve(params)).to eq('aaa' => 'dvalue_foo_bar_baz', 'bbb' => 'dvalue_foo_bar_bing', 'ccc' => 'dvalue_foo_bar', 'ddd' => 'dvalue')
  end

  it 'handles recursive array and hash substitutions' do
    params = {
      'a1' => 'v1_${a4}',
      'a2' => {
        'b1' => ['${a1}', '${a4}'],
        'b2' => {
          'c1' => '${a1}'
        }
      },
      'a3' => {
        'b1' => '${a4}'
      },
      'a4' => '${a5}',
      'a5' => 'v5'
    }

    resolved_params = {
      'a1' => 'v1_v5',
      'a2' => {
        'b1' => %w(v1_v5 v5),
        'b2' => {
          'c1' => 'v1_v5'
        }
      },
      'a3' => {
        'b1' => 'v5'
      },
      'a4' => 'v5',
      'a5' => 'v5'
    }

    expect(parameter_resolver.resolve(params)).to eq(resolved_params)
  end

  it 'handles nested substitutions' do
    params = {
      'ami_owner' => 'amazon',
      'ami' => '${ami://amzn-ami-hv*x86_64-gp2?owner=${ami_owner}}'
    }
    resolved_params = {
      'ami_owner' => 'amazon',
      'ami' => 'ami-deadbeef'
    }

    expect(resolver).to receive(:resolve).with(URI('ami://amzn-ami-hv*x86_64-gp2?owner=amazon')).and_return('ami-deadbeef')
    expect(parameter_resolver.resolve(params)).to eq(resolved_params)
  end

  it 'raises an error on a circular series of parameter references' do
    params = { 'aaa' => '${bbb}_foo', 'bbb' => '${ccc}_bar', 'ccc' => '${aaa}_baz' }
    expect { parameter_resolver.resolve(params) }.to raise_exception(Bora::ParameterResolver::UnresolvedSubstitutionError)
  end

  it 'raises an error if there are unresolved placeholders' do
    params = { 'aaa' => '${xxx}_foo_${bbb}', 'bbb' => 'bar' }
    expect { parameter_resolver.resolve(params) }.to raise_exception(Bora::ParameterResolver::UnresolvedSubstitutionError)
  end

  it 'raises an error if there are unresolved placeholders in recursive hashes and arrays' do
    params = {
      'a1' => {
        'b1' => '${a2}',
        'b2' => ['${a2}', '${invalid}']
      },
      'a2' => 'bar'
    }
    expect { parameter_resolver.resolve(params) }.to raise_exception(Bora::ParameterResolver::UnresolvedSubstitutionError)
  end

  it 'is compatible with legacy cfn output lookups' do
    params = { "key1": '${foo_stack/outputs/bar}' }
    expect(resolver).to receive(:resolve).with(URI('cfn://foo_stack/outputs/bar'))
    parameter_resolver.resolve(params)
  end

  it 'resolves multiple substitutions within the one parameter' do
    params = { "key1": '${foo://foo}bar${foo://foo}bar${foo://foo}bar' }
    expect(resolver).to receive(:resolve).exactly(3).times.with(URI('foo://foo')).and_return('foo')
    expect(parameter_resolver.resolve(params)).to eq("key1": 'foobarfoobarfoobar')
  end
end
