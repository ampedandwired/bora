require 'securerandom'
require 'tempfile'
require 'colorize'
require 'cfndsl'
require 'diffy'
require 'bora/cfn/stack'
require 'bora/stack_tasks'
require 'bora/parameter_resolver'

class Bora
  class Stack
    STACK_ACTION_SUCCESS_MESSAGE = "%s stack '%s' completed successfully".freeze
    STACK_ACTION_FAILURE_MESSAGE = "%s stack '%s' failed".freeze
    STACK_ACTION_NOT_CHANGED_MESSAGE = "%s stack '%s' skipped as template has not changed".freeze
    STACK_DOES_NOT_EXIST_MESSAGE = "Stack '%s' does not exist".freeze
    STACK_EVENTS_DO_NOT_EXIST_MESSAGE = "Stack '%s' has no events".freeze
    STACK_EVENTS_MESSAGE = "Events for stack '%s'".freeze
    STACK_OUTPUTS_DO_NOT_EXIST_MESSAGE = "Stack '%s' has no outputs".freeze
    STACK_PARAMETERS_DO_NOT_EXIST_MESSAGE = "Stack '%s' has no parameters".freeze
    STACK_VALIDATE_SUCCESS_MESSAGE = "Template for stack '%s' is valid".freeze
    STACK_DIFF_TEMPLATE_UNCHANGED_MESSAGE = 'Template has not changed'.freeze
    STACK_DIFF_PARAMETERS_UNCHANGED_MESSAGE = 'Parameters have not changed'.freeze
    STACK_DIFF_NO_CHANGES_MESSAGE = 'No changes will be applied'.freeze

    def initialize(stack_name, template_file, stack_config)
      @stack_name = stack_name
      @cfn_stack_name = stack_config['cfn_stack_name'] || stack_config['stack_name'] || @stack_name
      if stack_config['stack_name']
        puts "DEPRECATED: The 'stack_name' setting is deprecated. Please use 'cfn_stack_name' instead."
      end
      @template_file = template_file
      @stack_config = stack_config
      @region = @stack_config['default_region'] || Aws::CloudFormation::Client.new.config[:region]
      @cfn_stack = Cfn::Stack.new(@cfn_stack_name, @region)
      @resolver = ParameterResolver.new(self)
    end

    attr_reader :stack_name, :stack_config, :region, :template_file

    def rake_tasks
      StackTasks.new(self)
    end

    def apply(override_params = {}, pretty_json = false)
      cfn_options = generate(override_params, pretty_json)
      action = @cfn_stack.exists? ? 'update' : 'create'
      success = invoke_action(action.capitalize, action, cfn_options)
      if success
        outputs = @cfn_stack.outputs
        if outputs && !outputs.empty?
          puts 'Stack outputs'
          outputs.each { |output| puts output }
        end
      end
      success
    end

    def delete
      invoke_action('Delete', 'delete')
    end

    def diff(override_params = {}, context_lines = 3)
      cfn_options = generate(override_params)
      diff_parameters(cfn_options)
      diff_template(context_lines, cfn_options)
      diff_change_set(cfn_options)
    end

    def events
      events = @cfn_stack.events
      if events
        if !events.empty?
          puts STACK_EVENTS_MESSAGE % @cfn_stack_name
          events.each { |e| puts e }
        else
          puts STACK_EVENTS_DO_NOT_EXIST_MESSAGE % @cfn_stack_name
        end
      else
        puts STACK_DOES_NOT_EXIST_MESSAGE % @cfn_stack_name
      end
      events
    end

    def outputs
      outputs = @cfn_stack.outputs
      if outputs
        if !outputs.empty?
          puts "Outputs for stack '#{@cfn_stack_name}'"
          outputs.each { |output| puts output }
        else
          puts STACK_OUTPUTS_DO_NOT_EXIST_MESSAGE % @cfn_stack_name
        end
      else
        puts STACK_DOES_NOT_EXIST_MESSAGE % @cfn_stack_name
      end
      outputs
    end

    def parameters
      parameters = @cfn_stack.parameters
      if parameters
        if !parameters.empty?
          puts "Parameters for stack '#{@cfn_stack_name}'"
          parameters.each { |parameter| puts parameter }
        else
          puts STACK_PARAMETERS_DO_NOT_EXIST_MESSAGE % @cfn_stack_name
        end
      else
        puts STACK_DOES_NOT_EXIST_MESSAGE % @cfn_stack_name
      end
      parameters
    end

    def recreate(override_params = {})
      cfn_options = generate(override_params)
      invoke_action('Recreate', 'recreate', cfn_options)
    end

    def show(override_params = {})
      cfn_options = generate(override_params)
      puts get_new_template(cfn_options)
    end

    def show_current
      template = get_current_template
      puts template ? template : (STACK_DOES_NOT_EXIST_MESSAGE % @cfn_stack_name)
    end

    def status
      puts @cfn_stack.status
    end

    def validate(override_params = {})
      cfn_options = generate(override_params)
      is_valid = @cfn_stack.validate(cfn_options)
      puts STACK_VALIDATE_SUCCESS_MESSAGE % @cfn_stack_name if is_valid
      is_valid
    end

    def create_change_set(change_set_name, description = nil, override_params = {}, pretty_json = false)
      puts "Creating change set '#{change_set_name}' for stack '#{@cfn_stack_name}' in region #{@region}"
      cfn_options = generate(override_params, pretty_json)
      cfn_options[:description] = description if description
      change_set = @cfn_stack.create_change_set(change_set_name, cfn_options)
      puts change_set
      change_set
    end

    def list_change_sets
      puts @cfn_stack.list_change_sets.map(&:to_s).join("\n")
    end

    def describe_change_set(change_set_name)
      puts @cfn_stack.describe_change_set(change_set_name)
    end

    def delete_change_set(change_set_name)
      @cfn_stack.delete_change_set(change_set_name)
      puts "Deleted change set '#{change_set_name}' for stack '#{@cfn_stack_name}' in region #{@region}"
    end

    def execute_change_set(change_set_name)
      invoke_action("Execute change set '#{change_set_name}'", 'execute_change_set', change_set_name)
    end

    def resolved_params(override_params = {})
      params = @stack_config['params'] || {}
      params.merge!(override_params)
      @resolver.resolve(params)
    end

    protected

    def diff_parameters(cfn_options)
      current_params = current_cfn_parameters
      new_params = new_bora_parameters(cfn_options)
      default_params = template_default_parameters(cfn_options)
      new_params = default_params.merge(new_params || {}) if default_params

      current_params_str = params_as_string(current_params)
      new_params_str = params_as_string(new_params)
      if current_params_str || new_params_str
        puts 'Parameters'.colorize(mode: :bold)
        puts '----------'
        diff = Diffy::Diff.new(current_params_str, new_params_str).to_s(String.disable_colorization ? :text : :color).chomp
        puts diff && !diff.empty? ? diff : STACK_DIFF_PARAMETERS_UNCHANGED_MESSAGE
        puts
      end
    end

    def params_as_string(params)
      params ? params.sort.map { |k, v| "#{k} - #{v}" }.join("\n") + "\n" : nil
    end

    def template_default_parameters(cfn_options)
      params = nil
      template = JSON.parse(cfn_options[:template_body])
      if template['Parameters']
        params_with_defaults = template['Parameters'].select { |_, v| v['Default'] }
        unless params_with_defaults.empty?
          params = params_with_defaults.map { |k, v| [k, v['Default']] }.to_h
        end
      end
      params
    end

    def current_cfn_parameters
      params = nil
      if @cfn_stack.parameters && !@cfn_stack.parameters.empty?
        params = @cfn_stack.parameters.map { |p| [p.key, p.value] }.to_h
      end
      params
    end

    def new_bora_parameters(cfn_options)
      params = nil
      cfn_parameters = cfn_options[:parameters]
      if cfn_parameters && !cfn_parameters.empty?
        params = cfn_parameters.map { |p| [p[:parameter_key], p[:parameter_value]] }.to_h
      end
      params
    end

    def diff_template(context_lines, cfn_options)
      diff = Diffy::Diff.new(get_current_template, get_new_template(cfn_options),
                             context: context_lines,
                             include_diff_info: true)
      diff = diff.reject { |line| line =~ /^(---|\+\+\+|\\\\)/ }
      diff = diff.map do |line|
        case line
        when /^\+/
          line.chomp.colorize(:green)
        when /^-/
          line.chomp.colorize(:red)
        when /^@@/
          line.chomp.colorize(:cyan)
        else
          line.chomp
        end
      end
      diff = diff.join("\n")

      puts 'Template'.colorize(mode: :bold)
      puts '--------'
      puts diff && !diff.empty? ? diff : STACK_DIFF_TEMPLATE_UNCHANGED_MESSAGE
      puts
    end

    def diff_change_set(cfn_options)
      change_set_name = "cs-#{SecureRandom.uuid}"
      if @cfn_stack.exists?
        change_set = @cfn_stack.create_change_set(change_set_name, cfn_options)
        @cfn_stack.delete_change_set(change_set_name)
        if change_set.changes?
          puts 'Changes'.colorize(mode: :bold)
          puts '-------'
          puts change_set.to_s(changes_only: true)
          puts
        else
          puts 'Changes'.colorize(mode: :bold)
          puts '-------'
          puts STACK_DIFF_NO_CHANGES_MESSAGE
        end
      end
    end

    def generate(override_params = {}, pretty_json = false)
      cfn_options = cfn_options_from_stack_config
      params = resolved_params(override_params)
      if File.extname(@template_file) == '.rb'
        template_body = run_cfndsl(@template_file, params, pretty_json)
        template_json = JSON.parse(template_body)
        if template_json['Parameters']
          cfn_param_keys = template_json['Parameters'].keys
          cfn_params = params.select { |k, _v| cfn_param_keys.include?(k) }.map do |k, v|
            { parameter_key: k, parameter_value: v }
          end
          cfn_options[:parameters] = cfn_params unless cfn_params.empty?
        end
        cfn_options[:template_body] = template_body
      else
        cfn_options[:template_body] = File.read(@template_file)
        unless params.empty?
          cfn_options[:parameters] = params.map do |k, v|
            { parameter_key: k, parameter_value: v }
          end
        end
      end
      # binding.pry
      cfn_options
    end

    def invoke_action(action_desc, action, *args)
      puts "#{action_desc} stack '#{@cfn_stack_name}' in region #{@region}"
      success = @cfn_stack.send(action, *args) { |event| puts event }
      if success
        puts STACK_ACTION_SUCCESS_MESSAGE % [action_desc, @cfn_stack_name]
      else
        if success.nil?
          puts STACK_ACTION_NOT_CHANGED_MESSAGE % [action_desc, @cfn_stack_name]
        else
          raise(STACK_ACTION_FAILURE_MESSAGE % [action_desc, @cfn_stack_name])
        end
      end
      success
    end

    def run_cfndsl(template_file, params, pretty_json)
      temp_extras = Tempfile.new(['bora', '.yaml'])
      temp_extras.write(params.to_yaml)
      temp_extras.close
      cfndsl_model = CfnDsl.eval_file_with_extras(template_file, [[:yaml, temp_extras.path]])
      template_body = pretty_json ? JSON.pretty_generate(cfndsl_model) : cfndsl_model.to_json
      temp_extras.unlink
      template_body
    end

    def cfn_options_from_stack_config
      valid_options = %w(capabilities tags disable_rollback on_failure)

      cfn_options = @stack_config.select { |k| valid_options.include?(k) }
      # Expand any Tags to "key" => key, "value" => value pairs
      if cfn_options['tags']
        cfn_options['tags'] = cfn_options['tags'].map do |k, v|
          { key: k, value: v }
        end
      end
      cfn_options
    end

    def get_new_template(cfn_options)
      template = cfn_options[:template_body]
      JSON.pretty_generate(JSON.parse(template))
    end

    def get_current_template
      template = @cfn_stack.template
      template ? JSON.pretty_generate(JSON.parse(template)) : nil
    end
  end
end
