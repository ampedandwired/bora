require 'bora/cfn/stack'

class Bora
  module Resolver
    class Ami
      NoAMI = Class.new(StandardError)
      InvalidParameter = Class.new(StandardError)

      def initialize(stack)
      end

      def resolve(uri)
        ami_prefix = uri.host
        raise InvalidParameter, "Invalid ami parameter #{uri}" unless ami_prefix
        ec2 = Aws::EC2::Client.new
        images = ec2.describe_images(
          owners: ['self','amazon'],
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
        images.sort! { |a,b| a.creation_date <=> b.creation_date }.last

      end
    end
  end
end
