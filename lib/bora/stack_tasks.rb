require 'rake/tasklib'

module Bora
  class StackTasks < Rake::TaskLib
    def initialize(stack)
      @stack = stack
      define_tasks
    end


    protected

    def define_tasks
      define_apply_task
      define_current_template_task
      define_delete_task
      define_diff_task
      define_events_task
      define_new_template_task
      define_outputs_task
      define_recreate_task
      define_status_task
      define_validate_task
    end

    def define_apply_task
      within_namespace do
        desc "Creates (or updates) the '#{@stack.stack_name}' stack"
        task :apply do |_, args|
          @stack.apply(extract_params_from_args(args.extras))
        end
      end
    end

    def define_current_template_task
      within_namespace do
        desc "Shows the current template for '#{@stack.stack_name}' stack"
        task :current_template do
          @stack.current_template
        end
      end
    end

    def define_delete_task
      within_namespace do
        desc "Deletes the '#{@stack.stack_name}' stack"
        task :delete do
          @stack.delete
        end
      end
    end

    def define_diff_task
      within_namespace do
        desc "Diffs the new template with the '#{@stack.stack_name}' stack's current template"
        task :diff do |_, args|
          @stack.diff(extract_params_from_args(args.extras))
        end
      end
    end

    def define_events_task
      within_namespace do
        desc "Outputs the latest events from the '#{@stack.stack_name}' stack"
        task :events do
          @stack.events
        end
      end
    end

    def define_new_template_task
      within_namespace do
        desc "Shows the new template for '#{@stack.stack_name}' stack"
        task :new_template do |_, args|
          @stack.new_template(self.extract_params_from_args(args.extras))
        end
      end
    end

    def define_outputs_task
      within_namespace do
        desc "Shows the outputs from the '#{@stack.stack_name}' stack"
        task :outputs do
          @stack.outputs
        end
      end
    end

    def define_recreate_task
      within_namespace do
        desc "Recreates (deletes then creates) the '#{@stack.stack_name}' stack"
        task :recreate do |_, args|
          @stack.recreate(extract_params_from_args(args.extras))
        end
      end
    end

    def define_status_task
      within_namespace do
        desc "Displays the current status of the '#{@stack.stack_name}' stack"
        task :status do
          @stack.status
        end
      end
    end

    def define_validate_task
      within_namespace do
        desc "Checks the '#{@stack.stack_name}' stack's template for validity"
        task :validate do |_, args|
          @stack.validate(extract_params_from_args(args.extras))
        end
      end
    end

    def within_namespace
      namespace :stack do
        namespace @stack.stack_name do
          yield
        end
      end
    end


    protected

    def extract_params_from_args(args)
      args ? Hash[args.map { |arg| arg.split("=", 2) }] : {}
    end

  end
end
