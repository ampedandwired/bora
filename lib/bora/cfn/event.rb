require 'bora/cfn/status'

class Bora
  module Cfn
    class Event
      def initialize(event)
        @event = event
        @status = Status.new(@event.resource_status)
      end

      def respond_to_missing?(method_name, include_private = false)
        return false if method_name == :to_ary

        super
      end

      def method_missing(method_name, *args, &block)
        if method_name.to_s =~ /(.*)/
          @event.send(Regexp.last_match[1], *args, &block)
        else
          super
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
        status_reason = @event.resource_status_reason ? " - #{@event.resource_status_reason}" : ''
        "#{@event.timestamp.getlocal} - #{@event.resource_type} - #{@event.logical_resource_id} - #{@status}#{status_reason}"
      end
    end
  end
end
