require 'uri'
require 'bora/parameter_resolver_loader'

class Bora
  class ParameterResolver
    UnresolvedSubstitutionError = Class.new(StandardError)

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
          unresolved_placeholders_still_remain ||= unresolved_placeholder?(resolved_value)
          placeholders_were_substituted ||= resolved_value != v
          params[k] = resolved_value
        end
        if unresolved_placeholders_still_remain && !placeholders_were_substituted
          raise UnresolvedSubstitutionError, "Parameter substitutions could not be resolved:\n#{unresolved_placeholders_as_string(params)}"
        end
      end
      params
    end

    private

    def process_param_substitutions(val, params)
      result = val
      if val.is_a? String
        result = val.gsub(PLACEHOLDER_REGEX) do |placeholder|
          process_placeholder(placeholder, params)
        end
      elsif val.is_a? Array
        result = val.map { |i| process_param_substitutions(i, params) }
      elsif val.is_a? Hash
        result = val.map { |k, v| [k, process_param_substitutions(v, params)] }.to_h
      end
      result
    end

    def process_placeholder(placeholder, params)
      uri = parse_uri(placeholder[2..-2])
      if !uri.scheme
        # This token refers to another parameter, rather than a resolver
        value_to_substitute = params[uri.path]
        return !value_to_substitute || unresolved_placeholder?(value_to_substitute) ? placeholder : value_to_substitute
      else
        # This token needs to be resolved by a resolver
        resolver_name = uri.scheme
        resolver = @resolver_cache[resolver_name] || @loader.load_resolver(resolver_name).new(@stack)
        return resolver.resolve(uri)
      end
    end

    def unresolved_placeholder?(val)
      result = false
      if val.is_a? String
        result = val =~ PLACEHOLDER_REGEX
      elsif val.is_a? Array
        result = val.find { |i| unresolved_placeholder?(i) }
      elsif val.is_a? Hash
        result = val.find { |_, v| unresolved_placeholder?(v) }
      end
      result
    end

    def parse_uri(s)
      uri = URI(s)

      # Support for legacy CFN substitutions without a scheme, eg: ${stack/outputs/foo}.
      # Will be removed in next breaking version.
      if !uri.scheme && uri.path && uri.path.count('/') == 2
        uri = URI("cfn://#{s}")
      end
      uri
    end

    def unresolved_placeholders_as_string(params)
      params.select { |_k, v| unresolved_placeholder?(v) }.to_a.map { |k, v| "#{k}: #{v}" }.join("\n")
    end
  end
end
