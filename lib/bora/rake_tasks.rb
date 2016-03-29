require 'tempfile'
require 'yaml'
require 'colorize'
require 'rake/tasklib'
require 'cfndsl'
require 'bora/tasks'
require 'bora/cfn_param_resolver'

module Bora
  class RakeTasks < Rake::TaskLib
    def initialize(config_file_or_hash)
      define_templates(load_config(config_file_or_hash))
    end


    private

    def define_templates(config)
      config['templates'].each do |template_name, template_config|
        define_stacks(template_name, template_config)
      end
    end

    def define_stacks(template_name, template_config)
      template_file = template_config['template_file']
      template_config['stacks'].each do |stack_name, stack_config|
        stack_name = stack_config['stack_name'] || "#{template_name}-#{stack_name}"
        stack_options = extract_stack_options(template_config)
        define_tasks(template_file, stack_name, stack_config, stack_options)
      end
    end

    def define_tasks(template_file, stack_name, stack_config, stack_options)
      Bora::Tasks.new(stack_name) do |t|
        t.stack_options = stack_options

        task :generate do |_, args|
          params = extract_params(stack_config, args)
          t.stack_options[:parameters] = params.map do |k,v|
            { parameter_key: k, parameter_value: v }
          end

          if File.extname(template_file) == ".rb"
            template_body = run_cfndsl(template_file, params)
            template_json = JSON.parse(template_body)
            if template_json["Parameters"]
              cfn_params = template_json["Parameters"].keys
              t.stack_options[:parameters].keep_if {|cfn_param| cfn_params.include?(cfn_param[:parameter_key]) }
            end
            t.stack_options[:template_body] = template_body
          else
            t.stack_options[:template_url] = template_file
          end
        end
      end
    end

    def run_cfndsl(template_file, params)
      temp_extras = Tempfile.new("bora")
      temp_extras.write(params.to_yaml)
      temp_extras.close
      template_body = CfnDsl.eval_file_with_extras(template_file, [[:yaml, temp_extras.path]]).to_json
      temp_extras.unlink
      template_body
    end

    def extract_stack_options(config)
      valid_options = ["capabilities"]
      config.select { |k| valid_options.include?(k) }
    end

    def extract_params(stack_config, args)
      params = stack_config['params'] || {}
      params.merge!(extract_params_from_args(args.extras))
      params.map { |k, v| [k, process_param_substitutions(v)] }.to_h
    end

    def process_param_substitutions(val)
      old_val = nil
      while old_val != val
        old_val = val
        val = val.sub(/\${[^}]+}/) do |m|
          token = m[2..-2]
          CfnParamResolver.new(token).resolve
        end
      end
      val
    end

    def extract_params_from_args(args)
      args ? Hash[args.map { |arg| arg.split("=", 2) }] : {}
    end

    def load_config(config)
      if config.class == String
        return YAML.load_file(config)
      elsif config.class == Hash
        return config
      end
    end
  end
end
