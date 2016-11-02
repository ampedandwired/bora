require 'rake'
require 'bora/cli'

DEFAULT_REGION = "us-stubbed-1"

def setup_stack(stack_name, status: :not_created)
  stack = double(Bora::Cfn::Stack)
  allow(Bora::Cfn::Stack).to receive(:new).with(stack_name, DEFAULT_REGION).and_return(stack)

  if status == :not_created
    allow(stack).to receive(:status).and_return(Bora::Cfn::StackStatus.new(nil))
    allow(stack).to receive("exists?").and_return(false)
  else
    underlying_stack = OpenStruct.new
    underlying_stack.stack_status = status.to_s.upcase
    underlying_stack.stack_name = stack_name
    allow(stack).to receive(:status).and_return(Bora::Cfn::StackStatus.new(underlying_stack))
    allow(stack).to receive("exists?").and_return(true)
  end

  allow(stack).to receive(:outputs).and_return(nil)

  stack
end

def setup_outputs(stack, outputs)
  bora_outputs = outputs.map { |o| Bora::Cfn::Output.new(Aws::CloudFormation::Types::Output.new(o)) }
  allow(stack).to receive(:outputs).and_return(bora_outputs)
  bora_outputs
end

def setup_parameters(stack, parameters)
  bora_parameters = parameters.map { |o| Bora::Cfn::Parameter.new(Aws::CloudFormation::Types::Parameter.new(o)) }
  allow(stack).to receive(:parameters).and_return(bora_parameters)
  bora_parameters
end

def setup_template(bora_config, template_name, template)
  # Use a class variable to ensure ruby doesn't GC and delete the temp file until the spec is complete
  @_temp_template_file = Tempfile.new(["bora_template", ".yaml"])
  template = template.to_json if template.is_a?(Hash) || template.is_a?(Array)
  @_temp_template_file.write(template)
  @_temp_template_file.close
  template_path = @_temp_template_file.path
  bora_config["templates"][template_name]["template_file"] = template_path
  template_path
end

class BoraRunner
  def capture
    begin
      stream = StringIO.new
      $stdout = stream
      $stderr = stream
      yield
      result = stream.string
    ensure
      $stdout = STDOUT
      $stderr = STDERR
    end

    puts result
    result
  end
end

class BoraCli < BoraRunner
  def run(config, *params)
    bora_cfg = Tempfile.new(["bora", ".yaml"])
    bora_cfg.write(config.to_yaml)
    bora_cfg.close
    bora_cfg_path = bora_cfg.path
    thor_args = params + ["--file", bora_cfg_path]
    String.disable_colorization = true
    capture do
      begin
        Bora::Cli.start(thor_args)
      rescue Exception => e
        puts e
        puts e.backtrace
      end
    end
  end
end

class BoraRake < BoraRunner
  def run(config, cmd, stack, *params)
    Rake.application = Rake::Application.new
    bora = Bora.new(config_file_or_hash: config)
    String.disable_colorization = true
    capture do
      Rake.application.instance_eval do
        bora.rake_tasks
        begin
          Rake.application["#{stack}:#{cmd}"].invoke(*params)
        rescue Exception => e
          puts e
          puts e.backtrace
        end
      end
    end
  end
end
