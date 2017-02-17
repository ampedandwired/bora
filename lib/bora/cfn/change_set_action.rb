require 'colorize'

class Bora
  module Cfn
    class ChangeSetAction
      def initialize(action, replacement)
        @action = action
        @replacement = replacement
      end

      def to_s
        action_str = @action
        if @action == 'Modify'
          action_str = case @replacement
                       when 'True' then 'Replace'
                       when 'Conditional' then 'Replace (conditional)'
                       else action_str
                       end
        end
        action_str.colorize(color)
      end

      private

      def color
        case @action
        when 'Add' then :green
        when 'Remove' then :red
        else :yellow
        end
      end
    end
  end
end
