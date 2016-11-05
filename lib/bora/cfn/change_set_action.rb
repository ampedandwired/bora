require 'colorize'

class Bora
  module Cfn
    class ChangeSetAction
      def initialize(action)
        @action = action
      end

      def to_s
        @action.colorize(color)
      end


      private

      def color
        case @action
          when "Add"; :green
          when "Remove"; :red
          else; :yellow;
        end
      end
    end

  end
end
