require "bora/cfn/change"
require "bora/cfn/status"

class Bora
  module Cfn
    class ChangeSet
      def initialize(change_set)
        @change_set = change_set
        @status = Status.new(@change_set.status)
        @execution_status = Status.new(@change_set.execution_status)
        @changes = change_set.changes.map { |c| Change.new(c) }
      end

      def status_success?
        @status.success?
      end

      def status_failure?
        @status.failure?
      end

      def status_complete?
        status_success? || status_failure?
      end

      def to_s
        reason = @change_set.status_reason ? " (#{@change_set.status_reason})" : ""
        description = @change_set.description ? " - #{@change_set.description}" : ""
        changes_str = @changes.map(&:to_s).join("\n")
        "#{@change_set.change_set_name.bold} - #{@change_set.creation_time.getlocal} - #{@status}#{reason} - #{@execution_status}#{description}\n#{changes_str}"
      end
    end
  end
end
