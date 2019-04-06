require 'aws-sdk'
require 'bora/cfn/stack'
require 'English'

class Bora
  module Resolver
    class Credstash
      InvalidParameter = Class.new(StandardError)

      def initialize(stack)
        @stack = stack
      end

      def resolve(uri)
        raise InvalidParameter, "Invalid credstash parameter #{uri}: no credstash key" unless uri.path

        key = uri.path[1..-1]
        raise InvalidParameter, "Invalid credstash parameter #{uri}: no credstash key" if !key || key.empty?

        region = resolve_region(uri, @stack)
        context = parse_key_context(uri)
        output = `credstash --region #{region} get #{key}#{context}`
        # exit_code = $?
        raise NotFound, output unless $CHILD_STATUS.success?

        output.rstrip
      end

      private

      def resolve_region(uri, stack)
        region = uri.host || stack.region
        region
      end

      def parse_key_context(uri)
        return '' unless uri.query

        query = URI.decode_www_form(uri.query).to_h
        context_params = query.map { |k, v| "#{k}=#{v}" }.join(' ')
        " #{context_params}"
      end
    end
  end
end
