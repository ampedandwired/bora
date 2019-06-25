require 'bora/cfn/stack'
class Bora
  module Resolver
    class Acm
      NoACM = Class.new(StandardError)
      InvalidParameter = Class.new(StandardError)

      def initialize(stack)
        @stack = stack
      end

      def filter_certificates(certs, uri)
        correct_certs = []
        certs.each do |cert|
          correct_certs << cert if cert.domain_name == uri
        end
        correct_certs
      end

      def fetch_certificates
        acm_client = Aws::ACM::Client.new(region: @stack.region)
        acm_certs = []
        certs = nil
        next_token = nil
        until !certs.nil? && next_token.nil?
          acm_args = { certificate_statuses: ['ISSUED'], max_items: 10 }
          unless certs.nil?
            next_token = certs.next_token
            acm_args[:next_token] = next_token unless next_token.nil?
          end

          certs = acm_client.list_certificates(acm_args)
          acm_certs << certs.certificate_summary_list
        end
        acm_certs.flatten
      end

      def resolve(uri)
        acm_prefix = uri.host
        raise InvalidParameter, "Invalid ACM parameter #{uri}" unless acm_prefix

        acm_certs_all = fetch_certificates
        acm_certs = filter_certificates(acm_certs_all, uri.host)
        raise NoACM, "No Matching ACM certificates for #{uri.host}" if acm_certs.empty?

        acm_certs.first.certificate_arn
      end
    end
  end
end
