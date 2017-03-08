require 'aws-sdk'
require 'helper/spec_helper'
require 'pry'

TEST_STACK_NAME = 'test-stack'.freeze

now = Time.now

describe Bora::Cfn::Stack do
  before :each do
    @cfn = double(Aws::CloudFormation::Client)
    allow(Aws::CloudFormation::Client).to receive(:new).and_return(@cfn)
    @stack = Bora::Cfn::Stack.new(TEST_STACK_NAME)
  end

  context 'when the stack does not exist' do
    def expect_create_stack(options)
      allow(@cfn).to receive(:describe_stack_events).and_return(describe_stack_events_result(TEST_STACK_NAME, reason: 'just because'))
      expect(@cfn).to receive(:create_stack).with(options) do
        allow(@cfn).to receive(:describe_stacks).and_return(describe_stacks_result)
      end
    end

    before :each do
      validation_error = Aws::CloudFormation::Errors::ValidationError.new('Stack does not exist', 'Error')
      allow(@cfn).to receive(:describe_stacks).and_raise(validation_error)
      allow(@cfn).to receive(:create_change_set).and_raise(validation_error)
      allow(@cfn).to receive(:describe_change_set).and_raise(validation_error)
      allow(@cfn).to receive(:list_change_sets).and_raise(validation_error)
      allow(@cfn).to receive(:delete_change_set).and_raise(validation_error)
      allow(@cfn).to receive(:execute_change_set).and_raise(validation_error)
    end

    describe '#exists?' do
      it 'returns false' do
        expect(@stack.exists?).to be_falsy
      end
    end

    describe '#create' do
      it 'creates the stack' do
        options = { stack_name: TEST_STACK_NAME, template_body: '{"foo": "bar"}' }
        expect_create_stack(options)
        @stack.create(options) { |e| expect(e.resource_status_reason).to eq('just because') }
      end
    end

    describe '#recreate' do
      it 'behaves the same as create' do
        options = { stack_name: TEST_STACK_NAME, template_body: '{"foo": "bar"}' }
        expect_create_stack(options)
        expect(@cfn).to_not receive(:delete_stack)
        @stack.recreate(options)
      end
    end

    describe '#create_or_update' do
      it 'calls create' do
        options = { stack_name: TEST_STACK_NAME, template_body: '{"foo": "bar"}' }
        expect_create_stack(options)
        @stack.create_or_update(options)
      end
    end

    describe '#delete' do
      it "doesn't fail" do
        expect(@cfn).to_not receive(:delete_stack)
        expect(@stack.delete).to be_truthy
      end
    end

    describe '#events' do
      it 'returns nil' do
        expect(@stack.events).to be_nil
      end
    end

    describe '#outputs' do
      it 'returns nil' do
        expect(@stack.outputs).to be_nil
      end
    end

    describe '#parameters' do
      it 'returns nil' do
        expect(@stack.parameters).to be_nil
      end
    end

    describe '#template' do
      it 'returns nil' do
        expect(@stack.template).to be_nil
      end
    end

    describe '#status' do
      it 'return an object representing the current status of the stack' do
        expect(@stack.status.exists?).to be_falsey
      end
    end

    describe '#create_change_set' do
      it 'raises an exception if the stack does not exist' do
        expect { @stack.create_change_set('mychangeset', {}) }.to raise_exception(Aws::CloudFormation::Errors::ValidationError)
      end
    end

    describe '#list_change_sets' do
      it 'raises an exception if the stack does not exist' do
        expect { @stack.list_change_sets }.to raise_exception(Aws::CloudFormation::Errors::ValidationError)
      end
    end

    describe '#describe_change_set' do
      it 'raises an exception if the stack does not exist' do
        expect { @stack.describe_change_set('mychangeset') }.to raise_exception(Aws::CloudFormation::Errors::ValidationError)
      end
    end

    describe '#delete_change_set' do
      it 'raises an exception if the stack does not exist' do
        expect { @stack.delete_change_set('mychangeset') }.to raise_exception(Aws::CloudFormation::Errors::ValidationError)
      end
    end

    describe '#execute_change_set' do
      it 'raises an exception if the stack does not exist' do
        expect { @stack.execute_change_set('mychangeset') }.to raise_exception(Aws::CloudFormation::Errors::ValidationError)
      end
    end
  end

  context 'when the stack exists' do
    before :each do
      allow(@cfn).to receive(:describe_stacks).and_return(describe_stacks_result)
      allow(@cfn).to receive(:describe_stack_events).and_return(
        describe_stack_events_result(TEST_STACK_NAME, timestamp: now - 60),
        describe_stack_events_result(TEST_STACK_NAME, reason: 'just because')
      )
    end

    describe '#exists?' do
      it 'returns true' do
        expect(@stack.exists?).to be true
      end
    end

    describe '#update' do
      it 'updates the stack' do
        options = { stack_name: TEST_STACK_NAME, template_body: 'foo' }
        expect(@cfn).to receive(:update_stack).with(options)
        @stack.update(options) { |e| expect(e.resource_status_reason).to eq('just because') }
      end

      it 'returns nil if the template has not changed' do
        expect(@cfn).to receive(:update_stack).and_raise(Aws::CloudFormation::Errors::ValidationError.new('', Bora::Cfn::Stack::NO_UPDATE_MESSAGE))
        expect(@stack.update(template_body: 'foo')).to be_nil
      end

      it 'removes create stack only api parameters when updating a stack' do
        options = { stack_name: TEST_STACK_NAME, on_failure: 'DELETE', capabilities: ['CAPABILITY_IAM'], template_body: 'foo' }
        expect(@cfn).to receive(:update_stack).with(options).and_raise(validation_error)
        @stack.update(options)
        allow(@cfn).to receive(:describe_stacks).and_return(describe_stacks_result)
        #   allow(@cfn).to receive(:describe_stacks).and_return(describe_stacks_result)
        # end
        # expect @stack.update(options) { |e| expect(e.resource_status_reason).to eq('just because') }
        # # binding.pry
        # expect(@stack.update(options)).to be(true)
        #   .with(
        #     hash_including(
        #       :template_body,
        #       'capabilities' => ['CAPABILITY_IAM']
        #     )
        #   )
          # .and_return(true)
        # output = bora.run(bora_config, 'apply', 'web-prod')
        # expect(output).to include(format(Bora::Stack::STACK_ACTION_SUCCESS_MESSAGE, 'Update', 'web-prod'))
        # output = bora.run(bora_config, 'apply', 'web-prod')
        # binding.pry
        # expect(@cfn).to receive(:update_stack).and_include(format(Bora::Stack::STACK_ACTION_SUCCESS_MESSAGE, 'Update', 'web-prod'))
      end
    end

    describe '#recreate' do
      it 'deletes and then creates the stack' do
        expect(@cfn).to receive(:delete_stack) do
          allow(@cfn).to receive(:describe_stacks).and_raise(Aws::CloudFormation::Errors::ValidationError.new('Stack does not exist', 'Error'))
          allow(@cfn).to receive(:describe_stack_events).and_return(
            describe_stack_events_result(TEST_STACK_NAME, timestamp: now - 50), describe_stack_events_result(TEST_STACK_NAME)
          )
        end
        expect(@cfn).to receive(:create_stack) do
          allow(@cfn).to receive(:describe_stacks).and_return(describe_stacks_result)
        end
        @stack.recreate(template_body: 'foo')
      end
    end

    describe '#create_or_update' do
      it 'calls update' do
        expect(@cfn).to receive(:update_stack)
        @stack.create_or_update(template_body: 'foo')
      end
    end

    describe '#delete' do
      it 'deletes the stack' do
        expect(@cfn).to receive(:delete_stack)
        @stack.delete
      end
    end

    describe '#events' do
      it 'returns all events' do
        expect(@cfn).to receive(:describe_stack_events).and_return(describe_stack_events_result(TEST_STACK_NAME, count: 2))
        expect(@stack.events.length).to eq(2)
      end
    end

    describe '#outputs' do
      it 'returns all the stack outputs' do
        outputs = [
          { output_key: 'a', output_value: 'b', description: 'foo' },
          { output_key: 'd', output_value: 'e', description: 'bar' }
        ]
        allow(@cfn).to receive(:describe_stacks).and_return(describe_stacks_result(outputs: outputs))
        actual_outputs = @stack.outputs
        expect(actual_outputs.length).to eq(2)
        expect(actual_outputs[0].to_s).to include('foo')
      end
    end

    describe '#parameters' do
      it 'returns all the stack parameters' do
        parameters = [
          { parameter_key: 'a', parameter_value: 'foo' },
          { parameter_key: 'd', parameter_value: 'bar' }
        ]
        allow(@cfn).to receive(:describe_stacks).and_return(describe_stacks_result(parameters: parameters))
        actual_parameters = @stack.parameters
        expect(actual_parameters.length).to eq(2)
        expect(actual_parameters[0].to_s).to include('foo')
      end
    end

    describe '#template' do
      it 'returns the current stack template' do
        expect(@cfn).to receive(:get_template).at_least(:once).and_return(Hashie::Mash.new(template_body: '{"foo": "bar"}'))
        expect(@stack.template).to eq('{"foo": "bar"}')
      end
    end

    describe '#status' do
      it 'return an object representing the current status of the stack' do
        expect(@stack.status.exists?).to be_truthy
      end
    end

    describe '#create_change_set' do
      it 'creates a change set in cloudformation' do
        change_set_name = 'mychangeset'
        options = {
          stack_name: TEST_STACK_NAME,
          change_set_name: change_set_name
        }
        create_options = options.merge(capabilities: ['CAPABILITY_IAM'])
        expect(@cfn).to receive(:create_change_set).with(create_options)
        expect(@cfn).to receive(:describe_change_set).with(options)
          .and_return(describe_change_set_result(change_set_name, status: 'CREATE_COMPLETE', description: 'awesome change set'))
        change_set = @stack.create_change_set(change_set_name, capabilities: ['CAPABILITY_IAM'])
        expect(change_set.status_success?).to be_truthy
        expect(change_set.to_s).to include('awesome change set')
      end
    end

    describe '#list_change_sets' do
      it 'lists all the change sets available for this stack' do
        expect(@cfn).to receive(:list_change_sets)
          .with(hash_including(stack_name: TEST_STACK_NAME))
          .and_return(list_change_sets_result(['cs-1', 'cs-2']))
        change_sets = @stack.list_change_sets
        expect(change_sets.size).to eq(2)
        expect(change_sets[0].to_s).to include('cs-1')
        expect(change_sets[1].to_s).to include('cs-2')
      end
    end

    describe '#describe_change_set' do
      it 'returns the detail of the given change set' do
        change_set_name = 'mychangeset'
        expect(@cfn).to receive(:describe_change_set)
          .with(hash_including(stack_name: TEST_STACK_NAME, change_set_name: change_set_name))
          .and_return(describe_change_set_result(change_set_name))
        change_set = @stack.describe_change_set(change_set_name)
        expect(change_set.to_s).to include(change_set_name)
      end

      it 'raises an exception if the change set does not exist' do
        change_set_name = 'mychangeset'
        expect(@cfn).to receive(:describe_change_set).and_raise(Aws::CloudFormation::Errors::ChangeSetNotFound.new('', 'Change set does not exist'))
        expect { @stack.describe_change_set(change_set_name) }.to raise_exception(Aws::CloudFormation::Errors::ChangeSetNotFound)
      end
    end

    describe '#delete_change_set' do
      it 'deletes the given change set in cloudformation' do
        change_set_name = 'mychangeset'
        expect(@cfn).to receive(:delete_change_set)
          .with(hash_including(stack_name: TEST_STACK_NAME, change_set_name: change_set_name))
        @stack.delete_change_set(change_set_name)
      end
    end

    describe '#execute_change_set' do
      it 'applies the given change set' do
        change_set_name = 'mychangeset'
        options = { stack_name: TEST_STACK_NAME, change_set_name: change_set_name }
        expect(@cfn).to receive(:execute_change_set).with(options)
        @stack.execute_change_set(change_set_name) { |e| expect(e.resource_status_reason).to eq('just because') }
      end

      it 'raises an exception if the change set does not exist' do
        change_set_name = 'mychangeset'
        expect(@cfn).to receive(:execute_change_set).and_raise(Aws::CloudFormation::Errors::ChangeSetNotFound.new('', 'Change set does not exist'))
        expect { @stack.execute_change_set(change_set_name) }.to raise_exception(Aws::CloudFormation::Errors::ChangeSetNotFound)
      end
    end
  end

  describe '#validate' do
    it 'calls aws to validate the template' do
      expect(@cfn).to receive(:validate_template).with(template_body: 'foo')
      @stack.validate(template_body: 'foo', this: 'should not get passed')
    end
  end

  describe 'any update action' do
    it 'treats rollbacks as failures' do
      allow(@cfn).to receive(:describe_stacks).and_return(describe_stacks_result(status: 'ROLLBACK_COMPLETE'))
      allow(@cfn).to receive(:describe_stack_events).and_return(
        describe_stack_events_result(TEST_STACK_NAME, timestamp: now - 60), describe_stack_events_result(TEST_STACK_NAME, status: 'ROLLBACK_COMPLETE')
      )
      @stack = Bora::Cfn::Stack.new(TEST_STACK_NAME)
      expect(@cfn).to receive(:update_stack)
      result = @stack.update(template_body: 'foo')
      expect(result).to be_falsey
    end
  end
end
