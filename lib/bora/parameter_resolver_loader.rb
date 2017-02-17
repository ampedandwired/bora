class Bora
  class ParameterResolverLoader
    ResolverNotFound = Class.new(StandardError)

    def load_resolver(name)
      resolver_class = name.split('_').reject(&:empty?).map(&:capitalize).join
      class_name = "Bora::Resolver::#{resolver_class}"
      begin
        resolver_class = Kernel.const_get(class_name)
      rescue NameError
        require_resolver_file(name)
        resolver_class = Kernel.const_get(class_name)
      end
      resolver_class
    end

    private

    def require_resolver_file(name)
      require_path = "bora/resolver/#{name}"
      begin
        require require_path
      rescue LoadError
        raise ResolverNotFound, "Could not find resolver for '#{name}'. Expected to find it at '#{require_path}'"
      end
    end
  end
end
