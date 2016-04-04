require 'tempfile'
require 'colorize'
require 'cfndsl'
require 'bora/cfn/stack'
require 'bora/cfn_param_resolver'
require 'bora/stack_tasks'

class Bora
  class Stack
    def initialize(stack_name, template_file, stack_config)
      @stack_name = stack_name
      @cfn_stack_name = stack_config['stack_name'] || @stack_name
      @template_file = template_file
      @stack_config = stack_config
      @cfn_options = extract_cfn_options(stack_config)
      @cfn_stack = Cfn::Stack.new(@cfn_stack_name)
    end

    attr_reader :stack_name

    def rake_tasks
      StackTasks.new(self)
    end

    def apply(override_params = {})
      generate(override_params)
      success = invoke_action(@cfn_stack.exists? ? "update" : "create", @cfn_options)
      if success
        outputs = @cfn_stack.outputs
        if outputs && outputs.length > 0
          puts "Stack outputs"
          outputs.each { |output| puts output }
        end
      end
    end

    def show_current
      template = @cfn_stack.template
      puts template ? template : "Stack '#{@cfn_stack_name}' does not exist"
    end

    def delete
      invoke_action("delete")
    end

    def diff(override_params = {})
      generate(override_params)
      puts @cfn_stack.diff(@cfn_options).to_s(String.disable_colorization ? :text : :color)
    end

    def events
      events = @cfn_stack.events
      if events
        if events.length > 0
          puts "Events for stack '#{@cfn_stack_name}'"
          @cfn_stack.events.each { |e| puts e }
        else
          puts "Stack '#{@cfn_stack_name}' has no events"
        end
      else
        puts "Stack '#{@cfn_stack_name}' does not exist"
      end
    end

    def generate(override_params = {})
      params = process_params(override_params)
      if File.extname(@template_file) == ".rb"
        template_body = run_cfndsl(@template_file, params)
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

    def show(override_params = {})
      generate(override_params)
      puts @cfn_stack.new_template(@cfn_options)
    end

    def outputs
      outputs = @cfn_stack.outputs
      if outputs
        if outputs.length > 0
          puts "Outputs for stack '#{@cfn_stack_name}'"
          outputs.each { |output| puts output }
        else
          puts "Stack '#{@cfn_stack_name}' has no outputs"
        end
      else
        puts "Stack '#{@cfn_stack_name}' does not exist"
      end
    end

    def recreate(override_params = {})
      generate(override_params)
      invoke_action("recreate", @cfn_options)
    end

    def status
      puts @cfn_stack.status
    end

    def validate(override_params = {})
      generate(override_params)
      puts "Template for stack '#{@cfn_stack_name}' is valid" if @cfn_stack.validate(@cfn_options)
    end


    protected

    def invoke_action(action, *args)
      puts "#{action.capitalize} stack '#{@cfn_stack_name}'"
      success = @cfn_stack.send(action, *args) { |event| puts event }
      if success
        puts "#{action.capitalize} stack '#{@cfn_stack_name}' completed successfully"
      else
        if success == nil
          puts "#{action.capitalize} stack '#{@cfn_stack_name}' skipped as template has not changed"
        else
          raise("#{action.capitalize} stack '#{@cfn_stack_name}' failed")
        end
      end
      success
    end

    def run_cfndsl(template_file, params)
      temp_extras = Tempfile.new("bora")
      temp_extras.write(params.to_yaml)
      temp_extras.close
      template_body = CfnDsl.eval_file_with_extras(template_file, [[:yaml, temp_extras.path]]).to_json
      temp_extras.unlink
      template_body
    end

    def process_params(override_params)
      params = @stack_config['params'] || {}
      params.merge!(override_params)
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

    def extract_cfn_options(config)
      valid_options = ["capabilities"]
      config.select { |k| valid_options.include?(k) }
    end

  end
end
