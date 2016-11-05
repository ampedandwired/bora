require 'set'
require 'open-uri'
require 'aws-sdk'
require 'bora/cfn/stack_status'
require 'bora/cfn/change_set'
require 'bora/cfn/event'
require 'bora/cfn/output'
require 'bora/cfn/parameter'

class Bora
  module Cfn

    class Stack
      NO_UPDATE_MESSAGE = "No updates are to be performed"

      def initialize(stack_name, region = nil)
        @stack_name = stack_name
        @region = region
        @processed_events = Set.new
      end

      def create(options, &block)
        call_cfn_action(:create, options, &block)
      end

      def update(options, &block)
        call_cfn_action(:update, options, &block)
      end

      def create_or_update(options, &block)
        exists? ? update(options, &block) : create(options, &block)
      end

      def recreate(options, &block)
        delete(&block) if exists?
        create(options, &block) if !exists?
      end

      def delete(&block)
        call_cfn_action(:delete, &block)
      end

      def events
        return if !exists?
        events = cloudformation.describe_stack_events({stack_name: underlying_stack.stack_id}).stack_events
        events.reverse.map { |e| Event.new(e) }
      end

      def outputs
        return if !exists?
        underlying_stack.outputs.map { |output| Output.new(output) }
      end

      def parameters
        return if !exists?
        underlying_stack.parameters.map { |parameter| Parameter.new(parameter) }
      end

      def template
        return if !exists?
        cloudformation.get_template({stack_name: @stack_name}).template_body
      end

      def validate(options)
        cloudformation.validate_template(options.select { |k| [:template_body, :template_url].include?(k) })
      end

      def status
        StackStatus.new(underlying_stack)
      end

      def exists?
        status.exists?
      end

      def create_change_set(change_set_name, options)
        cfn_create_change_set(change_set_name, options)
      end

      def list_change_sets
        cfn_change_sets = cloudformation.list_change_sets(stack_name: @stack_name)
        cfn_change_sets.summaries.map { |cs| ChangeSet.new(cs, true) }
      end


      # =============================================================================================
      private

      def cloudformation
        @cfn ||= begin
          @region ? Aws::CloudFormation::Client.new(region: @region) : Aws::CloudFormation::Client.new
        end
      end

      def call_cfn_action(action, options = {}, &block)
        underlying_stack(refresh: true)
        return true if action == :delete && !exists?
        @previous_event_time = last_event_time
        begin
          action_options = {stack_name: @stack_name}.merge(options)
          cloudformation.method("#{action.to_s.downcase}_stack").call(action_options)
          wait_for_completion(&block)
        rescue Aws::CloudFormation::Errors::ValidationError => e
          raise e unless e.message.include?(NO_UPDATE_MESSAGE)
          return nil
        end
        (action == :delete && !underlying_stack) || status.success?
      end

      def wait_for_completion
        begin
          events = unprocessed_events
          events.each { |e| yield e } if block_given?
          finished = events.find do |e|
            e.resource_type == 'AWS::CloudFormation::Stack' && e.logical_resource_id == @stack_name && e.status_complete?
          end
          sleep 10 unless finished
        end until finished
        underlying_stack(refresh: true)
      end

      def underlying_stack(refresh: false)
        if !@_stack || refresh
          begin
            response = cloudformation.describe_stacks({stack_name: @stack_name})
            @_stack = response.stacks[0]
          rescue Aws::CloudFormation::Errors::ValidationError
            @_stack = nil
          end
        end
        @_stack
      end

      def unprocessed_events
        return [] if !underlying_stack
        events = cloudformation.describe_stack_events({stack_name: underlying_stack.stack_id}).stack_events
        unprocessed_events = events.select do |event|
          !@processed_events.include?(event.event_id) && @previous_event_time < event.timestamp
        end
        @processed_events.merge(unprocessed_events.map(&:event_id))
        unprocessed_events.reverse.map { |e| Event.new(e) }
      end

      def last_event_time
        return Time.at(0) if !underlying_stack
        events = cloudformation.describe_stack_events({stack_name: @stack_name}).stack_events
        events.length > 0 ? events[0].timestamp : Time.at(0)
      end

      def cfn_create_change_set(change_set_name, options = {})
        change_set_options = {
          stack_name: @stack_name,
          change_set_name: change_set_name
        }
        cloudformation.create_change_set(change_set_options.merge(options))
        begin
          change_set = ChangeSet.new(cloudformation.describe_change_set(change_set_options))
          sleep 5 unless change_set.status_complete?
        end until change_set.status_complete?
        change_set
      end
    end


  end
end
