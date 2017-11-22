require 'yaml'
require 'colorize'
require 'bora/version'
require 'bora/template'
require 'bora/tasks'

class Bora
  DEFAULT_CONFIG_FILE = 'bora.yml'.freeze
  INHERITABLE_PROPERTIES = ['default_region'].freeze

  def initialize(config_file_or_hash: DEFAULT_CONFIG_FILE, override_config: {}, colorize: true)
    @templates = {}
    config = load_config(config_file_or_hash)
    String.disable_colorization = !colorize
    raise 'No templates defined' unless config['templates']
    config['templates'].each do |template_name, template_config|
      resolved_config = resolve_template_config(config, template_config, override_config)
      @templates[template_name] = Template.new(template_name, resolved_config, override_config)
    end
  end

  def template(name)
    @templates[name]
  end

  def templates
    @templates.values
  end

  def stack(stack_name)
    t = @templates.find { |_, template| !template.stack(stack_name).nil? }
    t ? t[1].stack(stack_name) : nil
  end

  def rake_tasks
    @templates.each_value { |_, t| t.rake_tasks }
  end

  protected

  def load_config(config)
    if config.class == String
      YAML.load_file(config)
    elsif config.class == Hash
      config
    end
  end

  private

  def resolve_template_config(bora_config, template_config, override_config)
    inheritable_properties(bora_config).merge(template_config).merge(inheritable_properties(override_config))
  end

  def inheritable_properties(config)
    config.select { |k| INHERITABLE_PROPERTIES.include?(k) }
  end
end
