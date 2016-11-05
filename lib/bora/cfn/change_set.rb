require "bora/cfn/change"
require "bora/cfn/status"

class Bora
  module Cfn
    class ChangeSet
      def initialize(change_set, is_summary = false)
        @change_set = change_set
        @is_summary = is_summary
        @status = Status.new(@change_set.status)
        @execution_status = Status.new(@change_set.execution_status)
        if !@is_summary
          @changes = change_set.changes.map { |c| Change.new(c) }
        end
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
        changes_str = !@is_summary ? @changes.map(&:to_s).join("\n") : nil
        s = "#{@change_set.change_set_name.bold} - #{@change_set.creation_time.getlocal} - #{@status}#{reason} - #{@execution_status}#{description}"
        s += "\n#{changes_str}" if changes_str
        s
      end
    end
  end
end
