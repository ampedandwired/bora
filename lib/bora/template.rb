require 'bora/stack'
require 'hashie'

class Bora
  class Template
    # These are properties that you can define on the template, but which can also be defined and overriden in the stack

    INHERITABLE_PROPERTIES = %w(capabilities default_region tags on_failure disable_rollback)

    # These are properties that can be passed in from the command line to override what's defined inthe stack
    OVERRIDABLE_PROPERTIES = %w(cfn_stack_name).freeze

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
      Hashie::Mash.new(
        inheritable_properties(template_config)
      ).deep_merge(stack_config).merge(overridable_properties(override_config))
    end

    def inheritable_properties(config)
      config.select { |k| INHERITABLE_PROPERTIES.include?(k) }
    end

    def overridable_properties(config)
      config.select { |k| INHERITABLE_PROPERTIES.include?(k) || OVERRIDABLE_PROPERTIES.include?(k) }
    end
  end
end
