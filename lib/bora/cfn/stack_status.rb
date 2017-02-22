require 'bora/cfn/status'

class Bora
  module Cfn
    class StackStatus
      DOES_NOT_EXIST_MESSAGE = 'Stack does not exist'.freeze

      def initialize(underlying_stack)
        @stack = underlying_stack
        @status = Status.new(@stack.stack_status) if @stack
      end

      def exists?
        @status && !@status.deleted?
      end

      def success?
        @status && @status.success?
      end

      def to_s
        if @stack
          status_reason = @stack.stack_status_reason ? " - #{@stack.stack_status_reason}" : ''
          "#{@stack.stack_name} - #{@status}#{status_reason}"
        else
          DOES_NOT_EXIST_MESSAGE
        end
      end
    end
  end
end
