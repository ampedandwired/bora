require 'tempfile'
require 'colorize'
require 'cfndsl'
require 'diffy'
require 'bora/cfn/stack'
require 'bora/stack_tasks'
require 'bora/parameter_resolver'

class Bora
  class Stack
    STACK_ACTION_SUCCESS_MESSAGE = "%s stack '%s' completed successfully"
    STACK_ACTION_FAILURE_MESSAGE = "%s stack '%s' failed"
    STACK_ACTION_NOT_CHANGED_MESSAGE = "%s stack '%s' skipped as template has not changed"
    STACK_DOES_NOT_EXIST_MESSAGE = "Stack '%s' does not exist"
    STACK_EVENTS_DO_NOT_EXIST_MESSAGE = "Stack '%s' has no events"
    STACK_EVENTS_MESSAGE = "Events for stack '%s'"
    STACK_OUTPUTS_DO_NOT_EXIST_MESSAGE = "Stack '%s' has no outputs"
    STACK_PARAMETERS_DO_NOT_EXIST_MESSAGE = "Stack '%s' has no parameters"
    STACK_VALIDATE_SUCCESS_MESSAGE = "Template for stack '%s' is valid"
    STACK_DIFF_TEMPLATE_UNCHANGED_MESSAGE = "Template has not changed"
    STACK_DIFF_PARAMETERS_UNCHANGED_MESSAGE = "Parameters have not changed"

    def initialize(stack_name, template_file, stack_config)
      @stack_name = stack_name
      @cfn_stack_name = stack_config['cfn_stack_name'] || stack_config['stack_name'] || @stack_name
      if stack_config['stack_name']
        puts "DEPRECATED: The 'stack_name' setting is deprecated. Please use 'cfn_stack_name' instead."
      end
      @template_file = template_file
      @stack_config = stack_config
      @region = @stack_config['default_region'] || Aws::CloudFormation::Client.new.config[:region]
      @cfn_options = extract_cfn_options(stack_config)
      @cfn_stack = Cfn::Stack.new(@cfn_stack_name, @region)
      @resolver = ParameterResolver.new(self)
    end

    attr_reader :stack_name, :stack_config, :region, :template_file

    def rake_tasks
      StackTasks.new(self)
    end

    def apply(override_params = {}, pretty_json = false)
      generate(override_params, pretty_json)
      success = invoke_action(@cfn_stack.exists? ? "update" : "create", @cfn_options)
      if success
        outputs = @cfn_stack.outputs
        if outputs && outputs.length > 0
          puts "Stack outputs"
          outputs.each { |output| puts output }
        end
      end
      success
    end

    def delete
      invoke_action("delete")
    end

    def diff(override_params = {}, context_lines = 3)
      generate(override_params)
      diff_parameters
      diff_template(override_params, context_lines)
    end

    def events
      events = @cfn_stack.events
      if events
        if events.length > 0
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
        if outputs.length > 0
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
        if parameters.length > 0
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
      generate(override_params)
      invoke_action("recreate", @cfn_options)
    end

    def show(override_params = {})
      generate(override_params)
      puts @cfn_stack.new_template(@cfn_options)
    end

    def show_current
      template = @cfn_stack.template
      puts template ? template : (STACK_DOES_NOT_EXIST_MESSAGE % @cfn_stack_name)
    end

    def status
      puts @cfn_stack.status
    end

    def validate(override_params = {})
      generate(override_params)
      is_valid = @cfn_stack.validate(@cfn_options)
      puts STACK_VALIDATE_SUCCESS_MESSAGE % @cfn_stack_name if is_valid
      is_valid
    end

    def resolved_params(override_params = {})
      params = @stack_config['params'] || {}
      params.merge!(override_params)
      @resolver.resolve(params)
    end


    protected

    def diff_parameters
      if @cfn_stack.parameters && !@cfn_stack.parameters.empty?
        current_params = @cfn_stack.parameters.sort { |a, b| a.key <=> b.key }.map(&:to_s).join("\n") + "\n"
      end
      if @cfn_options[:parameters] && !@cfn_options[:parameters].empty?
        new_params = @cfn_options[:parameters].sort { |a, b|
          a[:parameter_key] <=> b[:parameter_key]
        }.map { |p|
          "#{p[:parameter_key] } - #{p[:parameter_value]}"
        }.join("\n") + "\n"
      end

      if current_params || new_params
        puts "Parameters".colorize(mode: :bold)
        puts "----------"
        diff = Diffy::Diff.new(current_params, new_params).to_s(String.disable_colorization ? :text : :color).chomp
        puts diff && !diff.empty? ? diff : STACK_DIFF_PARAMETERS_UNCHANGED_MESSAGE
        puts
      end
    end

    def diff_template(override_params, context_lines)
      diff = Diffy::Diff.new(@cfn_stack.template, @cfn_stack.new_template(@cfn_options),
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

      puts "Template".colorize(mode: :bold)
      puts "--------"
      puts diff && !diff.empty? ? diff : STACK_DIFF_TEMPLATE_UNCHANGED_MESSAGE
      puts
    end

    def generate(override_params = {}, pretty_json = false)
      params = resolved_params(override_params)
      if File.extname(@template_file) == ".rb"
        template_body = run_cfndsl(@template_file, params, pretty_json)
        template_json = JSON.parse(template_body)
        if template_json["Parameters"]
          cfn_param_keys = template_json["Parameters"].keys
          cfn_params = params.select { |k, v| cfn_param_keys.include?(k) }.map do |k, v|
            { parameter_key: k, parameter_value: v }
          end
          @cfn_options[:parameters] = cfn_params if !cfn_params.empty?
        end
        @cfn_options[:template_body] = template_body
      else
        @cfn_options[:template_url] = @template_file
        if !params.empty?
          @cfn_options[:parameters] = params.map do |k, v|
            { parameter_key: k, parameter_value: v }
          end
        end
      end
    end

    def invoke_action(action, *args)
      puts "#{action.capitalize} stack '#{@cfn_stack_name}' in region #{@region}"
      success = @cfn_stack.send(action, *args) { |event| puts event }
      if success
        puts STACK_ACTION_SUCCESS_MESSAGE % [action.capitalize, @cfn_stack_name]
      else
        if success == nil
          puts STACK_ACTION_NOT_CHANGED_MESSAGE % [action.capitalize, @cfn_stack_name]
        else
          raise(STACK_ACTION_FAILURE_MESSAGE % [action.capitalize, @cfn_stack_name])
        end
      end
      success
    end

    def run_cfndsl(template_file, params, pretty_json)
      temp_extras = Tempfile.new(["bora", ".yaml"])
      temp_extras.write(params.to_yaml)
      temp_extras.close
      cfndsl_model = CfnDsl.eval_file_with_extras(template_file, [[:yaml, temp_extras.path]])
      template_body = pretty_json ? JSON.pretty_generate(cfndsl_model) : cfndsl_model.to_json
      temp_extras.unlink
      template_body
    end

    def extract_cfn_options(config)
      valid_options = ["capabilities"]
      config.select { |k| valid_options.include?(k) }
    end

  end
end
