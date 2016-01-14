require 'ostruct'
require 'aws-sdk'
require 'spec_helper'

TEST_STACK_NAME = "test-stack"

def describe_stack_events_result(status: "CREATE_COMPLETE", reason: nil)
  OpenStruct.new({
    stack_events: [
      OpenStruct.new({
        timestamp: Time.new,
        resource_type: "AWS::CloudFormation::Stack",
        logical_resource_id: TEST_STACK_NAME,
        resource_status: status,
        resource_status_reason: reason
      })
    ]
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

describe Bora::Stack do
  describe "#create" do
    context "when the stack does not currently exist" do
      it "creates the stack" do
        @cfn = double(Aws::CloudFormation::Client)
        allow(Aws::CloudFormation::Client).to receive(:new).and_return(@cfn)
        expect(@cfn).to receive(:create_stack).with(anything)

        @call_count = 0
        allow(@cfn).to receive(:describe_stacks) do
          @call_count += 1
          raise Aws::CloudFormation::Errors::ValidationError.new("Stack does not exist", "Error") if @call_count == 1
          describe_stacks_result
        end

        expect(@cfn).to receive(:describe_stack_events).with(anything).and_return(empty_describe_stack_events_result, describe_stack_events_result(reason: "just because"))

        @stack = Bora::Stack.new(TEST_STACK_NAME)
        @stack.create({}) { |e| expect(e.resource_status_reason).to eq("just because") }
      end
    end
  end
end
