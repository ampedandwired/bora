require 'uri'
require 'bora/parameter_resolver_loader'

class Bora
  class ParameterResolver
    def initialize
      @loader = ParameterResolverLoader.new
      @resolver_cache = {}
    end

    def resolve(params)
      params.map { |k, v| [k, process_param_substitutions(v)] }.to_h
    end


    private

    def process_param_substitutions(val)
      return val unless val.is_a? String
      old_val = nil
      while old_val != val
        old_val = val
        val = val.sub(/\${[^}]+}/) do |m|
          token = m[2..-2]
          uri = parse_uri(token)
          resolver_name = uri.scheme
          resolver = @resolver_cache[resolver_name] || @loader.load_resolver(resolver_name).new
          resolver.resolve(uri)
        end
      end
      val
    end

    def parse_uri(s)
      uri = URI(s)

      # Support for legacy CFN substitutions without a scheme, eg: ${stack/outputs/foo}.
      # Will be removed in next breaking version.
      if !uri.scheme && uri.path && uri.path.count("/") == 2
        uri = URI("cfn://#{s}")
      end

      uri
    end

  end
end
