# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bora/version'

Gem::Specification.new do |spec|
  spec.name          = 'bora'
  spec.version       = Bora::VERSION
  spec.authors       = ['Charles Blaxland']
  spec.email         = ['charles.blaxland@gmail.com']

  spec.summary       = 'A tool (including rake tasks) for working with cloudformation stacks'
  spec.homepage      = 'https://github.com/ampedandwired/bora'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.2.0'

  spec.add_dependency 'aws-sdk', '~> 2.0'
  spec.add_dependency 'cfndsl', '~> 0.4'
  spec.add_dependency 'colorize', '~> 0.7'
  spec.add_dependency 'deep_merge', '~> 1.1'
  spec.add_dependency 'diffy', '~> 3.0'
  spec.add_dependency 'rake', '~> 10.0'
  spec.add_dependency 'thor', '~> 0.19'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'hashie', '~> 3.4.6'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.12'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'pry'
end
