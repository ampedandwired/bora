require 'ostruct'
require 'aws-sdk'
require 'spec_helper'

TEST_STACK_NAME = "test-stack"

def describe_stack_events_result(timestamp: Time.new, status: "CREATE_COMPLETE", reason: nil)
  OpenStruct.new({
    stack_events: [
      OpenStruct.new({
        timestamp: timestamp,
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
  before :each do
    @cfn = double(Aws::CloudFormation::Client)
    allow(Aws::CloudFormation::Client).to receive(:new).and_return(@cfn)
  end

  context "when the stack does not yet exist" do

    before :each do
      @describe_stacks_call_count = 0
      allow(@cfn).to receive(:describe_stacks) do
        @describe_stacks_call_count += 1
        raise Aws::CloudFormation::Errors::ValidationError.new("Stack does not exist", "Error") if @describe_stacks_call_count == 1
        describe_stacks_result
      end
      @stack = Bora::Stack.new(TEST_STACK_NAME)
    end

    describe "#create" do
      it "creates the stack" do
        allow(@cfn).to receive(:describe_stack_events).with(anything).and_return(empty_describe_stack_events_result, describe_stack_events_result(reason: "just because"))
        options = { stack_name: TEST_STACK_NAME, template_body: "foo" }
        expect(@cfn).to receive(:create_stack).with(options)
        @stack.create(options) { |e| expect(e.resource_status_reason).to eq("just because") }
      end
    end

    describe "#exists?" do
      it "returns false" do
        expect(@stack.exists?).to be_falsy
      end
    end

  end

  describe "#update" do
    it "updates the stack" do
      allow(@cfn).to receive(:describe_stacks).and_return(describe_stacks_result)
      allow(@cfn).to receive(:describe_stack_events).with(anything).and_return(describe_stack_events_result(timestamp: Time.now - 60), describe_stack_events_result(reason: "just because"))

      options = { stack_name: TEST_STACK_NAME, template_body: "foo" }
      expect(@cfn).to receive(:update_stack).with(options)
      @stack = Bora::Stack.new(TEST_STACK_NAME)
      @stack.update(options) { |e| expect(e.resource_status_reason).to eq("just because") }
    end
  end

end
