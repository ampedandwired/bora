require 'rake/tasklib'
require 'bora/stack'

module Bora
  class Tasks < Rake::TaskLib
    def initialize(stack_name)
      @stack_name = stack_name
      @stack = Stack.new(stack_name)
      @colorize = true
      yield self if block_given?
      define_tasks
    end

    attr_accessor :stack_params, :colorize

    private

    def define_tasks
      define_apply_task
      define_delete_task
    end

    def define_apply_task
      within_namespace do
        desc "Creates (or updates) the #{@stack_name} stack"
        task :apply do
          invoke_action(@stack.exists? ? "update" : "create", stack_params)
        end
      end
    end

    def define_delete_task
      within_namespace do
        desc "Deletes the #{@stack_name} stack"
        task :delete do
          invoke_action("delete")
        end
      end
    end

    def invoke_action(action, *args)
      puts "#{action.capitalize} stack #{@stack_name}"
      success = @stack.send(action, *args) { |event| puts event.to_s(colorize) }
      if success
        puts "#{action.capitalize} stack #{@stack_name} completed successfully"
      else
        fail("#{action.capitalize} stack #{@stack_name} failed")
      end
    end

    def within_namespace
      namespace :stack do
        namespace @stack_name do
          yield
        end
      end
    end

  end
end
