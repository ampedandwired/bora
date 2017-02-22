require 'bora/cfn/change_set_action'

class Bora
  module Cfn
    class Change
      def initialize(change)
        @change = change
        @resource_change = @change.resource_change
        @action = ChangeSetAction.new(@resource_change.action, @resource_change.replacement)
      end

      def to_s
        "#{@action} - #{@resource_change.resource_type} - #{@resource_change.logical_resource_id}"
      end
    end
  end
end
