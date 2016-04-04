require 'colorize'
require 'bora/cfn/stack'

module Bora
  class Stack
    def initialize(stack_name, template_uri = nil)
      @stack_name = stack_name
      @cfn_stack = Bora::Cfn::Stack.new(stack_name)
      @colorize = true
      @stack_options = {}

      if template_uri
        if @stack_options[:template_body] || @stack_options[:template_url]
          raise "You cannot specify a template in the constructor as well as in the stack_options"
        else
          @stack_options[:template_url] = template_uri
        end
      end

    end

    attr_reader :stack_name
    attr_accessor :stack_options

    def colorize=(value)
      @colorize = value
      String.disable_colorization = !@colorize
    end

    def apply
      success = invoke_action(@cfn_stack.exists? ? "update" : "create", @stack_options)
      if success
        outputs = @cfn_stack.outputs
        if outputs && outputs.length > 0
          puts "Stack outputs"
          outputs.each { |output| puts output }
        end
      end
    end

    def current_template
      template = @cfn_stack.template
      puts template ? template : "Stack '#{@stack_name}' does not exist"
    end

    def delete
      invoke_action("delete")
    end

    def diff
      puts @cfn_stack.diff(@stack_options).to_s(@colorize ? :color : :text)
    end

    def events
      events = @cfn_stack.events
      if events
        if events.length > 0
          puts "Events for stack '#{@stack_name}'"
          @cfn_stack.events.each { |e| puts e }
        else
          puts "Stack '#{@stack_name}' has no events"
        end
      else
        puts "Stack '#{@stack_name}' does not exist"
      end
    end

    def new_template
      puts @cfn_stack.new_template(@stack_options)
    end

    def outputs
      outputs = @cfn_stack.outputs
      if outputs
        if outputs.length > 0
          puts "Outputs for stack '#{@stack_name}'"
          outputs.each { |output| puts output }
        else
          puts "Stack '#{@stack_name}' has no outputs"
        end
      else
        puts "Stack '#{@stack_name}' does not exist"
      end
    end

    def recreate
      invoke_action("recreate", @stack_options)
    end

    def status
      puts @cfn_stack.status
    end

    def validate
      puts "Template for stack '#{@stack_name}' is valid" if @cfn_stack.validate(@stack_options)
    end

    def invoke_action(action, *args)
      puts "#{action.capitalize} stack '#{@stack_name}'"
      success = @cfn_stack.send(action, *args) { |event| puts event }
      if success
        puts "#{action.capitalize} stack '#{@stack_name}' completed successfully"
      else
        if success == nil
          puts "#{action.capitalize} stack '#{@stack_name}' skipped as template has not changed"
        else
          raise("#{action.capitalize} stack '#{@stack_name}' failed")
        end
      end
      success
    end

  end
end
