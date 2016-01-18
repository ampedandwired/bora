require 'colorize'
require 'bora/status'

module Bora
  class Event
    def initialize(event)
      @event = event
      @status = Status.new(@event.resource_status)
    end

    def method_missing(sym, *args, &block)
      @event.send(sym, *args, &block)
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

    def to_s(colorize = true)
      status_reason = @event.resource_status_reason ? " - #{@event.resource_status_reason}" : ""
      "#{@event.timestamp.getlocal} - #{@event.resource_type} - #{@event.logical_resource_id} - #{@status.to_s(colorize)}#{status_reason}"
    end
  end
end
