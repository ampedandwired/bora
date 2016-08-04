require 'aws-sdk'
require 'bora/cfn/stack'

class Bora
  module Resolver
    class Credstash
      InvalidParameter = Class.new(StandardError)

      def resolve(uri)
        raise InvalidParameter, "Invalid credstash parameter #{uri}" if !uri.path
        key = uri.path[1..-1]
        raise InvalidParameter, "Invalid credstash parameter #{uri}" if !key || key.empty?
        context = parse_key_context(uri)
        region = resolve_region
        output = `credstash --region #{region} get #{key}#{context}`
        exit_code = $?
        raise NotFound, output if exit_code.exitstatus != 0
        output
      end


      private

      def resolve_region
        # Get default region from AWS SDK. There's probably a better way to do this.
        Aws::CloudFormation::Client.new.config[:region]
      end

      def parse_key_context(uri)
        return "" if !uri.query
        query = URI::decode_www_form(uri.query).to_h
        context_params = query.map { |k,v| "#{k}=#{v}" }.join(" ")
        " #{context_params}"
      end

    end
  end
end
