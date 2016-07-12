$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'aws-sdk'
require 'bora'
require 'helper/cfn_helper'
require 'helper/stack_helper'

# Make sure we don't accidentally make calls to AWS during tests
Aws.config[:stub_responses] = true

String.disable_colorization = true
