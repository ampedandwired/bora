require 'bora/stack'

class Bora
  class Template
    # These are properties that you can define on the template, but which can also be defined in the stack
    INHERITABLE_PROPERTIES = ["capabilities", "default_region"]

    # These are properties that can be passed in from the command line to override what's defined inthe stack
    OVERRIDABLE_PROPERTIES = ["cfn_stack_name"]

    def initialize(template_name, template_config, override_config = {})
      @template_name = template_name
      @template_config = template_config
      @stacks = {}
      template_config['stacks'].each do |stack_name, stack_config|
        stack_name = "#{template_name}-#{stack_name}"
        resolved_config = resolve_stack_config(template_config, stack_config, override_config)
        @stacks[stack_name] = Stack.new(stack_name, template_config['template_file'], resolved_config)
      end
    end

    def stack(name)
      @stacks[name]
    end

    def stacks
      @stacks.values
    end

    def rake_tasks
      @stacks.each { |_, s| s.rake_tasks }
    end


    private

    def resolve_stack_config(template_config, stack_config, override_config)
      inheritable_properties(template_config).merge(stack_config).merge(overridable_properties(override_config))
    end

    def inheritable_properties(config)
      config.select { |k| INHERITABLE_PROPERTIES.include?(k) }
    end

    def overridable_properties(config)
      config.select { |k| INHERITABLE_PROPERTIES.include?(k) || OVERRIDABLE_PROPERTIES.include?(k) }
    end

  end
end
