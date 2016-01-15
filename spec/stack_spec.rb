require 'ostruct'
require 'aws-sdk'
require 'spec_helper'

TEST_STACK_NAME = "test-stack"

describe Bora::Stack do
  before :each do
    @cfn = double(Aws::CloudFormation::Client)
    allow(Aws::CloudFormation::Client).to receive(:new).and_return(@cfn)
  end

  context "when the stack does not yet exist" do
    def setup_create_stack
      @describe_stacks_call_count = 0
      allow(@cfn).to receive(:describe_stacks) do
        @describe_stacks_call_count += 1
        raise Aws::CloudFormation::Errors::ValidationError.new("Stack does not exist", "Error") if @describe_stacks_call_count == 1
        describe_stacks_result
      end
      allow(@cfn).to receive(:describe_stack_events).and_return(empty_describe_stack_events_result, describe_stack_events_result(reason: "just because"))
    end

    before :each do
      allow(@cfn).to receive(:describe_stacks).and_raise(Aws::CloudFormation::Errors::ValidationError.new("Stack does not exist", "Error"))
      allow(@cfn).to receive(:describe_stack_events).at_least(:once).and_return(empty_describe_stack_events_result)
      @stack = Bora::Stack.new(TEST_STACK_NAME)
    end

    describe "#exists?" do
      it "returns false" do
        expect(@stack.exists?).to be_falsy
      end
    end

    describe "#create" do
      it "creates the stack" do
        setup_create_stack
        options = { stack_name: TEST_STACK_NAME, template_body: "foo" }
        expect(@cfn).to receive(:create_stack).with(options)
        @stack.create(options) { |e| expect(e.resource_status_reason).to eq("just because") }
      end
    end

    describe "#create_or_update" do
      it "calls create" do
        setup_create_stack
        allow(@cfn).to receive(:describe_stack_events).and_return(empty_describe_stack_events_result, describe_stack_events_result(reason: "just because"))
        expect(@cfn).to receive(:create_stack)
        @stack.create_or_update({})
      end
    end

    describe "#delete" do
      it "doesn't fail" do
        expect(@cfn).to_not receive(:delete_stack)
        expect(@stack.delete).to be_truthy
      end
    end

  end

  describe "#update" do
    it "updates the stack" do
      allow(@cfn).to receive(:describe_stacks).and_return(describe_stacks_result)
      allow(@cfn).to receive(:describe_stack_events).and_return(describe_stack_events_result(timestamp: Time.now - 60), describe_stack_events_result(reason: "just because"))

      options = { stack_name: TEST_STACK_NAME, template_body: "foo" }
      expect(@cfn).to receive(:update_stack).with(options)
      @stack = Bora::Stack.new(TEST_STACK_NAME)
      @stack.update(options) { |e| expect(e.resource_status_reason).to eq("just because") }
    end
  end

end
