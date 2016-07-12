require 'securerandom'
require 'aws-sdk'

def stack_event(stack_name, timestamp: Time.new, status: "CREATE_COMPLETE", reason: nil)
  OpenStruct.new({
    timestamp: timestamp,
    event_id: SecureRandom.uuid,
    resource_type: "AWS::CloudFormation::Stack",
    logical_resource_id: stack_name,
    resource_status: status,
    resource_status_reason: reason
  })
end

def describe_stack_events_result(stack_name, timestamp: Time.new, status: "CREATE_COMPLETE", reason: nil, count: 1)
  events = []
  count.times { events << stack_event(stack_name, timestamp: timestamp, status: status, reason: reason) }
  OpenStruct.new({
    stack_events: events
  })
end

def empty_describe_stack_events_result
  OpenStruct.new({ stack_events: [] })
end

def describe_stacks_result(status: "CREATE_COMPLETE", outputs: [])
  OpenStruct.new({
    stacks: [
      OpenStruct.new({
        stack_status: status,
        outputs: outputs.map { |o| OpenStruct.new(o) }
      })
    ]
  })
end
