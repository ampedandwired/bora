require 'bora/stack'

class Bora
  class Template
    INHERITABLE_PROPERTIES = ["capabilities", "default_region"]

    def initialize(template_name, template_config)
      @template_name = template_name
      @template_config = template_config
      @stacks = {}
      template_config['stacks'].each do |stack_name, stack_config|
        stack_name = "#{template_name}-#{stack_name}"
        stack_config = resolve_stack_config(template_config, stack_config)
        @stacks[stack_name] = Stack.new(stack_name, template_config['template_file'], stack_config)
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

    def resolve_stack_config(template_config, stack_config)
      inheritable_properties(template_config).merge(stack_config)
    end

    def inheritable_properties(config)
      config.select { |k| INHERITABLE_PROPERTIES.include?(k) }
    end

  end
end
