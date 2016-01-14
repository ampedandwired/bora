require 'set'
require 'aws-sdk'

module Bora
  class Stack
    def initialize(stack_name)
      @stack_name = stack_name
      @cfn = Aws::CloudFormation::Client.new
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

    def delete(&block)
      call_cfn_action(:delete, &block)
    end

    def events
      return [] if !underlying_stack
      events = @cfn.describe_stack_events({stack_name: underlying_stack.stack_id}).stack_events
      events.reverse.map { |e| Event.new(e) }
    end

    def template(pretty = true)
      return if !exists?
      template = @cfn.get_template({stack_name: @stack_name}).template_body
      template = JSON.pretty_generate(JSON.parse(template)) if pretty
      template
    end

    def exists?
      underlying_stack && underlying_stack.stack_status != 'DELETE_COMPLETE'
    end


    private

    def call_cfn_action(action, options = {}, &block)
      underlying_stack(refresh: true)
      return true if action == :delete && !exists?
      @previous_event_time = last_event_time
      options[:stack_name] = @stack_name
      begin
        @cfn.method("#{action.to_s.downcase}_stack").call(options)
        wait_for_completion(&block)
      rescue Aws::CloudFormation::Errors::ValidationError => e
        raise e unless e.message.include?("No updates are to be performed")
      end
      (action == :delete && !underlying_stack) || underlying_stack.stack_status.end_with?('_COMPLETE')
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
          response = @cfn.describe_stacks({stack_name: @stack_name})
          @_stack = response.stacks[0]
        rescue Aws::CloudFormation::Errors::ValidationError
          @_stack = nil
        end
      end
      @_stack
    end

    def unprocessed_events
      return [] if !underlying_stack
      events = @cfn.describe_stack_events({stack_name: underlying_stack.stack_id}).stack_events
      unprocessed_events = events.select do |event|
        !@processed_events.include?(event.event_id) && @previous_event_time < event.timestamp
      end
      @processed_events.merge(unprocessed_events.map(&:event_id))
      unprocessed_events.reverse.map { |e| Event.new(e) }
    end

    def last_event_time
      return Time.at(0) if !underlying_stack
      events = @cfn.describe_stack_events({stack_name: @stack_name}).stack_events
      events.length > 0 ? events[0].timestamp : Time.at(0)
    end

  end
end
