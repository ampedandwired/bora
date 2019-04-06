$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift File.expand_path('../fixtures', __dir__)

require 'simplecov'
SimpleCov.start do
  add_filter '/.direnv/'
  add_filter '/spec/'
  add_filter '/lib/bora/tasks.rb' # This file is deprecated
end

require 'aws-sdk'
require 'bora'
require 'helper/cfn_helper'
require 'helper/stack_helper'

# Make sure we don't accidentally make calls to AWS during tests
Aws.config[:stub_responses] = true

String.disable_colorization = true
