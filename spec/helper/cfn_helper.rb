require 'securerandom'
require 'aws-sdk'

def describe_stack_events_result(stack_name, timestamp: Time.new, status: 'CREATE_COMPLETE', reason: nil, count: 1)
  events = []
  count.times do
    events << {
      timestamp: timestamp,
      event_id: SecureRandom.uuid,
      resource_type: 'AWS::CloudFormation::Stack',
      logical_resource_id: stack_name,
      resource_status: status,
      resource_status_reason: reason
    }
  end
  Hashie::Mash.new(stack_events: events)
end

def empty_describe_stack_events_result
  Hasie::Mash.new(stack_events: [])
end

def describe_stacks_result(status: 'CREATE_COMPLETE', outputs: [], parameters: [])
  Hashie::Mash.new(
    stacks: [
      {
        stack_status: status,
        outputs: outputs,
        parameters: parameters
      }
    ]
  )
end

def change_set_base_result(change_set_name)
  {
    change_set_name: change_set_name,
    status: 'CREATE_COMPLETE',
    status_reason: 'Finished',
    execution_status: 'AVAILABLE',
    description: 'My change set',
    creation_time: Time.parse('2016-07-21 15:01:00')
  }
end

def describe_change_set_result(change_set_name, **args)
  result = change_set_base_result(change_set_name)
  result[:changes] = [{
    resource_change: {
      action: 'Modify',
      resource_type: 'AWS::EC2::SecurityGroup',
      logical_resource_id: 'MySG'
    }
  }]

  Hashie::Mash.new(result).deep_merge(args)
end

def list_change_sets_result(change_set_names)
  summaries = change_set_names.map { |name| change_set_base_result(name) }
  Hashie::Mash.new(summaries: summaries)
end
