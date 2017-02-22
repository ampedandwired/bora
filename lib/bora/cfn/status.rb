require 'colorize'

class Bora
  module Cfn
    class Status
      def initialize(status)
        @status = status
      end

      def success?
        @status.end_with?('_COMPLETE') && !@status.include?('ROLLBACK')
      end

      def failure?
        @status.end_with?('FAILED') || @status.include?('ROLLBACK')
      end

      def deleted?
        @status == 'DELETE_COMPLETE'
      end

      def complete?
        success? || failure?
      end

      def to_s
        @status.colorize(color)
      end

      private

      def color
        if success? then :green
        elsif failure? then :red
        else; :yellow
        end
      end
    end
  end
end
