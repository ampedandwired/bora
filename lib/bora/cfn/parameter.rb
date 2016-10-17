class Bora
  module Cfn
    class Parameter
      def initialize(parameter)
        @parameter = parameter
      end

      def key
        @parameter.parameter_key
      end

      def value
        @parameter.parameter_value
      end

      def to_s
        "#{key} - #{value}"
      end
    end

  end
end
