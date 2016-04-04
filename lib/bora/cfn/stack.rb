require 'set'
require 'open-uri'
require 'aws-sdk'
require 'diffy'
require 'bora/cfn/stack_status'
require 'bora/cfn/event'
require 'bora/cfn/output'

class Bora
  module Cfn

    class Stack
      NO_UPDATE_MESSAGE = "No updates are to be performed"

      def initialize(stack_name)
        @stack_name = stack_name
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

      def template(pretty = true)
        return if !exists?
        template = cloudformation.get_template({stack_name: @stack_name}).template_body
        template = JSON.pretty_generate(JSON.parse(template)) if pretty
        template
      end

      def new_template(options, pretty = true)
        options = resolve_options(options, true)
        template = options[:template_body]
        if template
          template = JSON.pretty_generate(JSON.parse(template)) if pretty
          template
        else
          raise "new_template not yet implemented for URL #{options[:template_url]}"
        end
      end

      def diff(options)
        Diffy::Diff.new(template, new_template(options))
      end

      def validate(options)
        cloudformation.validate_template(resolve_options(options).select { |k| [:template_body, :template_url].include?(k) })
      end

      def status
        StackStatus.new(underlying_stack)
      end

      def exists?
        status.exists?
      end


      # =============================================================================================
      private

      def cloudformation
        @cfn ||= Aws::CloudFormation::Client.new
      end

      def method_missing(sym, *args, &block)
        underlying_stack ? underlying_stack.send(sym, *args, &block) : nil
      end

      def call_cfn_action(action, options = {}, &block)
        underlying_stack(refresh: true)
        return true if action == :delete && !exists?
        @previous_event_time = last_event_time
        begin
          action_options = {stack_name: @stack_name}.merge(resolve_options(options))
          cloudformation.method("#{action.to_s.downcase}_stack").call(action_options)
          wait_for_completion(&block)
        rescue Aws::CloudFormation::Errors::ValidationError => e
          raise e unless e.message.include?(NO_UPDATE_MESSAGE)
          return nil
        end
        (action == :delete && !underlying_stack) || status.success?
      end

      def resolve_options(options, load_all = false)
        return options if options[:template_body] || !options[:template_url]
        uri = URI(options[:template_url])
        if uri.scheme != "s3" || load_all
          resolved_options = options.clone
          resolved_options[:template_body] = open(options[:template_url]).read
          resolved_options.delete(:template_url)
          resolved_options
        else
          options
        end
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
    end

  end
end
