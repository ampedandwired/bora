require "thor"
require "bora"

class Bora
  class Cli < Thor
    class_option :file,
      type: :string,
      aliases: :f,
      default: Bora::DEFAULT_CONFIG_FILE,
      desc: "The Bora config file to use"

    class_option :region,
      type: :string,
      aliases: :r,
      default: nil,
      desc: "The region to use for the stack operation. Overrides any regions specified in the Bora config file."

    class_option "cfn-stack-name",
      type: :string,
      aliases: :n,
      default: nil,
      desc: "The name to give the stack in CloudFormation. Overrides any CFN stack name setting in the Bora config file."

    desc "list", "Lists the available stacks"
    def list
      templates = bora(options.file).templates
      stacks = templates.collect { |t| t.stacks }.flatten
      stack_names = stacks.collect { |s| s.stack_name }
      puts stack_names.join("\n")
    end

    desc "apply STACK_NAME", "Creates or updates the stack"
    option :params, type: :array, aliases: :p, desc: "Parameters to be passed to the template, eg: --params 'instance_type=t2.micro'"
    option :pretty, type: :boolean, default: false, desc: "Send pretty (formatted) JSON to AWS (only works for cfndsl templates)"
    def apply(stack_name)
      stack(options.file, stack_name).apply(params, options.pretty)
    end

    desc "delete STACK_NAME", "Deletes the stack"
    def delete(stack_name)
      stack(options.file, stack_name).delete
    end

    desc "diff STACK_NAME", "Diffs the new template with the stack's current template"
    option :params, type: :array, aliases: :p, desc: "Parameters to be passed to the template, eg: --params 'instance_type=t2.micro'"
    option :context, type: :numeric, aliases: :c, default: 3, desc: "Number of lines of context to show around the differences"
    def diff(stack_name)
      stack(options.file, stack_name).diff(params, options.context)
    end

    desc "events STACK_NAME", "Outputs the latest events from the stack"
    def events(stack_name)
      stack(options.file, stack_name).events
    end

    desc "outputs STACK_NAME", "Shows the outputs from the stack"
    def outputs(stack_name)
      stack(options.file, stack_name).outputs
    end

    desc "parameters STACK_NAME", "Shows the parameters from the stack"
    def parameters(stack_name)
      stack(options.file, stack_name).parameters
    end

    desc "recreate STACK_NAME", "Recreates (deletes then creates) the stack"
    option :params, type: :array, aliases: :p, desc: "Parameters to be passed to the template, eg: --params 'instance_type=t2.micro'"
    def recreate(stack_name)
      stack(options.file, stack_name).recreate(params)
    end

    desc "show STACK_NAME", "Shows the new template for stack"
    option :params, type: :array, aliases: :p, desc: "Parameters to be passed to the template, eg: --params 'instance_type=t2.micro'"
    def show(stack_name)
      stack(options.file, stack_name).show(params)
    end

    desc "show_current STACK_NAME", "Shows the current template for the stack"
    def show_current(stack_name)
      stack(options.file, stack_name).show_current
    end

    desc "status STACK_NAME", "Displays the current status of the stack"
    def status(stack_name)
      stack(options.file, stack_name).status
    end

    desc "validate STACK_NAME", "Checks the stack's template for validity"
    option :params, type: :array, aliases: :p, desc: "Parameters to be passed to the template, eg: --params 'instance_type=t2.micro'"
    def validate(stack_name)
      stack(options.file, stack_name).validate(params)
    end


    private

    def stack(config_file, stack_name)
      region = options.region
      cfn_stack_name = options["cfn-stack-name"]

      override_config = {}
      override_config["default_region"] = region if region
      override_config["cfn_stack_name"] = cfn_stack_name if cfn_stack_name

      bora = bora(config_file, override_config)
      stack = bora.stack(stack_name)
      if !stack
        STDERR.puts "Could not find stack #{stack_name}"
        exit(1)
      end
      stack
    end

    def bora(config_file, override_config = {})
      Bora.new(config_file_or_hash: config_file, override_config: override_config)
    end

    def params
      options.params ? Hash[options.params.map { |param| param.split("=", 2) }] : {}
    end

  end
end
