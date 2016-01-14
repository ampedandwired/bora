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

    attr_accessor :stack_options, :colorize

    private

    def define_tasks
      define_apply_task
      define_current_template_task
      define_delete_task
      define_diff_task
      define_events_task
      define_new_template_task
    end

    def define_apply_task
      within_namespace do
        desc "Creates (or updates) the #{@stack_name} stack"
        task :apply do
          invoke_action(@stack.exists? ? "update" : "create", stack_options)
        end
      end
    end

    def define_current_template_task
      within_namespace do
        desc "Shows the current template for #{@stack_name} stack"
        task :current_template do
          template = @stack.template
          puts template ? template : "Stack #{@stack_name} does not exist"
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

    def define_diff_task
      within_namespace do
        desc "Diffs the new template with the #{@stack_name} stack's current template"
        task :diff do
          puts @stack.diff(@stack_options).to_s(@colorize ? :color : :text)
        end
      end
    end

    def define_events_task
      within_namespace do
        desc "Outputs the latest events from the #{@stack_name} stack"
        task :events do
          events = @stack.events
          if events.length > 0
            @stack.events.each { |e| puts e }
          else
            puts "No events for stack #{@stack_name}"
          end
        end
      end
    end

    def define_new_template_task
      within_namespace do
        desc "Shows the new template for #{@stack_name} stack"
        task :new_template do
          puts @stack.new_template(@stack_options)
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
