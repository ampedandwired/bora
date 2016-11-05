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
        ami_pattern = uri.host
        raise InvalidParameter, "Invalid ami parameter #{uri}" unless ami_pattern

        ec2 = Aws::EC2::Client.new(region: @stack.region)
        images = ec2.describe_images(
          filters: [
            {
              name:   'name',
              values: [ami_pattern]
            },
            {
              name:   'state',
              values: ['available']
            }
          ]
        ).images

        raise NoAMI, "No Matching AMI's for #{ami_pattern}" if images.empty?
        images.sort! { |a, b| DateTime.parse(a.creation_date) <=> DateTime.parse(b.creation_date) }.last.image_id
      end
    end
  end
end
