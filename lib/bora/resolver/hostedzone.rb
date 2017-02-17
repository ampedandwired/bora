require 'aws-sdk'
require 'bora/cfn/stack'

class Bora
  module Resolver
    class Hostedzone
      InvalidParameterError = Class.new(StandardError)
      NotFoundError = Class.new(StandardError)
      MultipleMatchesError = Class.new(StandardError)

      def initialize(stack); end

      def resolve(uri)
        zone_name = uri.host
        zone_type = uri.path[1..-1]
        raise InvalidParameterError, "Invalid hostedzone parameter #{uri}" unless zone_name
        zone_name += '.'
        route53 = Aws::Route53::Client.new
        res = route53.list_hosted_zones
        zones = res.hosted_zones.select do |hz|
          hz.name == zone_name && zone_type_matches(zone_type, hz.config.private_zone)
        end
        raise NotFoundError, "Could not find hosted zone #{uri}" if !zones || zones.empty?
        raise MultipleMatchesError, "Multiple candidates for hosted zone #{uri}. Use public/private discrimiator." if zones.size > 1
        zones[0].id.split('/')[-1]
      end

      private

      def zone_type_matches(required_zone_type, is_private_zone)
        return true if !required_zone_type || required_zone_type.empty?
        (required_zone_type == 'private' && is_private_zone) || (required_zone_type == 'public' && !is_private_zone)
      end
    end
  end
end
