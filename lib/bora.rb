require "yaml"
require "colorize"
require "bora/version"
require "bora/template"
require "bora/tasks"

module Bora
  class Bora
    def initialize(config_file_or_hash = "bora.yml", colorize: true)
      @templates = {}
      config = load_config(config_file_or_hash)
      String.disable_colorization = !colorize
      config['templates'].each do |template_name, template_config|
        @templates[template_name] = Template.new(template_name, template_config)
      end
    end

    def template(name)
      @templates[name]
    end

    def rake_tasks
      @templates.each { |_, t| t.rake_tasks }
    end


    protected

    def load_config(config)
      if config.class == String
        return YAML.load_file(config)
      elsif config.class == Hash
        return config
      end
    end

  end
end
