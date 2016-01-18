require 'colorize'

module Bora
  class Status
    def initialize(status)
      @status = status
    end

    def success?
      @status.end_with?("_COMPLETE") && !@status.include?("ROLLBACK")
    end

    def failure?
      @status.end_with?("_FAILED") || @status.include?("ROLLBACK")
    end

    def deleted?
      @status == "DELETE_COMPLETE"
    end

    def complete?
      success? || failure?
    end

    def to_s(colorize = true)
      colorize ? @status.colorize(color) : @status
    end


    private

    def color
      case
        when success?; :green
        when failure?; :red
        else; :yellow;
      end
    end

  end
end
