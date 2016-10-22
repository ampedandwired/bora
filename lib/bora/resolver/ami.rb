require 'bora/cfn/stack'

class Bora
  module Resolver
    class Ami
      NoAMI = Class.new(StandardError)
      InvalidParameter = Class.new(StandardError)

      def initialize(stack)
        @stack = stack
      end

      def resolve(uri)
        owner = 'self' # Default to account owner
        ami_prefix = uri.host
        raise InvalidParameter, "Invalid ami parameter #{uri}" unless ami_prefix
        if !uri.query.nil? && uri.query.include?('owner')
          query = URI.decode_www_form(uri.query).to_h
          owner = query['owner']
        end

        ec2 = Aws::EC2::Client.new(region: @stack.region)
        images = ec2.describe_images(
          owners: [owner],
          filters: [
            {
              name:   'name',
              values: [ami_prefix]
            },
            {
              name:   'state',
              values: ['available']
            }
          ]
        ).images

        raise NoAMI, "No Matching AMI's for prefix #{ami_prefix}" if images.empty?
        images.sort! { |a, b| DateTime.parse(a.creation_date) <=> DateTime.parse(b.creation_date) }.last.image_id
      end
    end
  end
end
