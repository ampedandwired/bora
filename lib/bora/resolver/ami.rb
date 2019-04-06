require 'bora/cfn/stack'
class Bora
  module Resolver
    class Ami
      NoAMI = Class.new(StandardError)
      InvalidParameter = Class.new(StandardError)
      InvalidUserId = Class.new(StandardError)

      def initialize(stack)
        @stack = stack
      end

      def resolve(uri)
        owners = []
        ami_prefix = uri.host
        raise InvalidParameter, "Invalid ami parameter #{uri}" unless ami_prefix

        if !uri.query.nil? && uri.query.include?('owner')
          query = URI.decode_www_form(uri.query).to_h
          owners = query['owner'].split(',')
        else
          owners << 'self'
        end

        ec2 = Aws::EC2::Client.new(region: @stack.region)
        begin
          images = ec2.describe_images(
            owners: owners,
            filters: [
              {
                name: 'name',
                values: [ami_prefix]
              },
              {
                name: 'state',
                values: ['available']
              }
            ]
          ).images
        rescue Aws::EC2::Errors::InvalidUserIDMalformed
          raise InvalidUserId, "Invalid owner argument in #{uri}"
        end

        raise NoAMI, "No Matching AMI's for prefix #{ami_prefix}" if images.empty?

        images.sort! { |a, b| DateTime.parse(a.creation_date) <=> DateTime.parse(b.creation_date) }.last.image_id
      end
    end
  end
end
