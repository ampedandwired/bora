$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'aws-sdk'
require 'bora'

# Make sure we don't accidentally make calls to AWS during tests
Aws.config[:stub_responses] = true
