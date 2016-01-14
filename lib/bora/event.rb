require 'colorize'

module Bora
  class Event
    def initialize(event)
      @event = event
    end

    def method_missing(sym, *args, &block)
      @event.send(sym, *args, &block)
    end

    def status_success?
      @event.resource_status.end_with?("_COMPLETE")
    end

    def status_failure?
      @event.resource_status.end_with?("_FAILED")
    end

    def status_complete?
      status_success? || status_failure?
    end

    def to_s(colorize = true)
      color = case
        when status_success?; :green
        when status_failure?; :red
        else; :yellow;
      end
      status = colorize ? @event.resource_status.colorize(color) : @event.resource_status
      status_reason = @event.resource_status_reason ? " - #{@event.resource_status_reason}" : ""
      "#{@event.timestamp} - #{@event.resource_type} - #{@event.logical_resource_id} - #{status}#{status_reason}"
    end
  end
end
