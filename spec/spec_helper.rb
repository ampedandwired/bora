$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'securerandom'
require 'aws-sdk'
require 'bora'

# Make sure we don't accidentally make calls to AWS during tests
Aws.config[:stub_responses] = true

def stack_event(timestamp: Time.new, status: "CREATE_COMPLETE", reason: nil)
  OpenStruct.new({
    timestamp: timestamp,
    event_id: SecureRandom.uuid,
    resource_type: "AWS::CloudFormation::Stack",
    logical_resource_id: TEST_STACK_NAME,
    resource_status: status,
    resource_status_reason: reason
  })
end

def describe_stack_events_result(timestamp: Time.new, status: "CREATE_COMPLETE", reason: nil, count: 1)
  events = []
  count.times { events << stack_event(timestamp: timestamp, status: status, reason: reason) }
  OpenStruct.new({
    stack_events: events
  })
end

def empty_describe_stack_events_result
  OpenStruct.new({ stack_events: [] })
end

def describe_stacks_result(status: "CREATE_COMPLETE")
  OpenStruct.new({
    stacks: [
      OpenStruct.new({
        stack_status: status
      })
    ]
  })
end
