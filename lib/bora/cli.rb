require "thor"
require "bora"

class Bora
  class Cli < Thor
    class_option :file, type: :string, aliases: :f, default: Bora::DEFAULT_CONFIG_FILE

    desc "apply STACK_NAME", "Creates or updates the stack"
    def apply(stack_name)
      stack(options[:file], stack_name).apply
    end

    desc "delete STACK_NAME", "Deletes the stack"
    def delete(stack_name)
      stack(options[:file], stack_name).delete
    end

    desc "diff STACK_NAME", "Diffs the new template with the stack's current template"
    def diff(stack_name)
      stack(options[:file], stack_name).diff
    end

    desc "events STACK_NAME", "Outputs the latest events from the stack"
    def events(stack_name)
      stack(options[:file], stack_name).events
    end

    desc "outputs STACK_NAME", "Shows the outputs from the stack"
    def outputs(stack_name)
      stack(options[:file], stack_name).outputs
    end

    desc "recreate STACK_NAME", "Recreates (deletes then creates) the stack"
    def recreate(stack_name)
      stack(options[:file], stack_name).recreate
    end

    desc "show STACK_NAME", "Shows the new template for stack"
    def show(stack_name)
      stack(options[:file], stack_name).show
    end

    desc "show_current STACK_NAME", "Shows the current template for the stack"
    def show_current(stack_name)
      stack(options[:file], stack_name).show_current
    end

    desc "status STACK_NAME", "Displays the current status of the stack"
    def status(stack_name)
      stack(options[:file], stack_name).status
    end

    desc "validate STACK_NAME", "Checks the stack's template for validity"
    def validate(stack_name)
      stack(options[:file], stack_name).validate
    end


    private

    def stack(config_file, stack_name)
      bora = Bora.new(config_file)
      stack = bora.stack(stack_name)
      if !stack
        STDERR.puts "Could not find stack #{stack_name}"
        exit(1)
      end
      stack
    end

  end
end
