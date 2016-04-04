require 'colorize'
require 'rake/tasklib'
require 'bora/stack'
require 'bora/cfn/stack'

module Bora
  class StackTasks < Rake::TaskLib
    def initialize(stack_name, template_uri = nil)
      @stack = Stack.new(stack_name, template_uri)
      within_namespace { yield self } if block_given?
      define_tasks
    end

    def stack_name
      @stack.stack_name
    end

    def stack_options
      @stack.stack_options
    end

    def stack_options=(options)
      @stack.stack_options = options
    end

    def colorize=(value)
      @stack.colorize = value
    end

    protected

    def define_tasks
      define_apply_task
      define_current_template_task
      define_delete_task
      define_diff_task
      define_events_task
      define_generate_task
      define_new_template_task
      define_outputs_task
      define_recreate_task
      define_status_task
      define_validate_task
    end

    def define_apply_task
      within_namespace do
        desc "Creates (or updates) the '#{stack_name}' stack"
        task :apply => :generate do
          @stack.apply
        end
      end
    end

    def define_current_template_task
      within_namespace do
        desc "Shows the current template for '#{stack_name}' stack"
        task :current_template do
          @stack.current_template
        end
      end
    end

    def define_delete_task
      within_namespace do
        desc "Deletes the '#{stack_name}' stack"
        task :delete do
          @stack.delete
        end
      end
    end

    def define_diff_task
      within_namespace do
        desc "Diffs the new template with the '#{stack_name}' stack's current template"
        task :diff => :generate do
          @stack.diff
        end
      end
    end

    def define_events_task
      within_namespace do
        desc "Outputs the latest events from the '#{stack_name}' stack"
        task :events do
          @stack.events
        end
      end
    end

    def define_generate_task
      within_namespace do
        task :generate
      end
    end

    def define_new_template_task
      within_namespace do
        desc "Shows the new template for '#{stack_name}' stack"
        task :new_template => :generate do
          @stack.new_template
        end
      end
    end

    def define_outputs_task
      within_namespace do
        desc "Shows the outputs from the '#{stack_name}' stack"
        task :outputs do
          @stack.outputs
        end
      end
    end

    def define_recreate_task
      within_namespace do
        desc "Recreates (deletes then creates) the '#{stack_name}' stack"
        task :recreate => :generate do
          @stack.recreate
        end
      end
    end

    def define_status_task
      within_namespace do
        desc "Displays the current status of the '#{stack_name}' stack"
        task :status do
          @stack.status
        end
      end
    end

    def define_validate_task
      within_namespace do
        desc "Checks the '#{stack_name}' stack's template for validity"
        task :validate => :generate do
          @stack.validate
        end
      end
    end

    def within_namespace
      namespace :stack do
        namespace stack_name do
          yield
        end
      end
    end

  end

end
