require 'bora/cfn/stack'

class Bora
  class CfnParamResolver
    def initialize(param)
      @param = param
    end

    def resolve
      stack_name, section, name = @param.split("/")
      if !stack_name || !section || !name || section != 'outputs'
        raise "Invalid parameter substitution: #{@param}"
      end

      stack = Cfn::Stack.new(stack_name)
      if !stack.exists?
        raise "Output #{name} not found in stack #{stack_name} as the stack does not exist"
      end

      outputs = stack.outputs || []
      matching_output = outputs.find { |output| output.key == name }
      if !matching_output
        raise "Output #{name} not found in stack #{stack_name}"
      end

      matching_output.value
    end

  end
end
