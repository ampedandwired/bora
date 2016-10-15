require 'uri'
require 'bora/parameter_resolver_loader'

class Bora
  class ParameterResolver
    CircularReferenceError = Class.new(StandardError)

    PLACEHOLDER_REGEX = /\${[^}]+}/

    def initialize(stack)
      @stack = stack
      @loader = ParameterResolverLoader.new
      @resolver_cache = {}
    end

    def resolve(params)
      unresolved_placeholders_still_remain = true
      while unresolved_placeholders_still_remain
        unresolved_placeholders_still_remain = false
        placeholders_were_substituted = false
        params.each do |k, v|
          resolved_value = process_param_substitutions(v, params)
          unresolved_placeholders_still_remain ||= has_unresolved_placeholder?(resolved_value)
          placeholders_were_substituted ||= resolved_value != v
          params[k] = resolved_value
        end
        if unresolved_placeholders_still_remain && !placeholders_were_substituted
          raise CircularReferenceError, "Circular reference detected in parameter substitutions:\n#{unresolved_placeholders_as_string(params)}"
        end
      end
      params
    end


    private

    def process_param_substitutions(val, params)
      return val unless val.is_a? String
      val.gsub(PLACEHOLDER_REGEX) do |placeholder|
        process_placeholder(placeholder, params)
      end
    end

    def process_placeholder(placeholder, params)
      uri = parse_uri(placeholder[2..-2])
      if !uri.scheme
        # This token refers to another parameter, rather than a resolver
        value_to_substitute = params[uri.path]
        has_unresolved_placeholder?(value_to_substitute) ? placeholder : value_to_substitute
      else
        # This token needs to be resolved by a resolver
        resolver_name = uri.scheme
        resolver = @resolver_cache[resolver_name] || @loader.load_resolver(resolver_name).new(@stack)
        resolver.resolve(uri)
      end
    end

    def has_unresolved_placeholder?(val)
      val =~ PLACEHOLDER_REGEX
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

    def unresolved_placeholders_as_string(params)
      params.select { |k, v| has_unresolved_placeholder?(v) }.to_a.map { |k, v| "#{k}: #{v}" }.join("\n")
    end

  end
end
