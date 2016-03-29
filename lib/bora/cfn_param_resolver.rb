require 'bora/stack'

module Bora
  class CfnParamResolver
    def initialize(param)
      @param = param
    end

    def resolve
      stack, section, name = @param.split("/")
      if !stack || !section || !name || section != 'outputs'
        raise "Invalid parameter substitution: #{@param}"
      end

      outputs = Stack.new(stack).outputs
      matching_output = outputs.find { |output| output.key == name }
      raise "Output #{name} not found in stack #{stack}" if !matching_output
      matching_output.value
    end

  end
end
