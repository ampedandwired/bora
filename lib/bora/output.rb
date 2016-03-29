module Bora
  class Output
    def initialize(output)
      @output = output
    end

    def key
      @output.output_key
    end

    def value
      @output.output_value
    end

    def to_s
      desc = @output.description ? " (#{@output.description})" : ""
      "#{@output.output_key} - #{@output.output_value} #{desc}"
    end
  end
end
