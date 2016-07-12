require 'rake'
require 'bora/cli'

def setup_stack(stack_name, status: :not_created)
  stack = double(Bora::Cfn::Stack)
  allow(Bora::Cfn::Stack).to receive(:new).with(stack_name).and_return(stack)

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

class BoraRunner
  def capture(stream = :stdout)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end
end

class BoraCli < BoraRunner
  def run(config, cmd, *params)
    bora_cfg = Tempfile.new(["bora", ".yaml"])
    bora_cfg.write(config.to_yaml)
    bora_cfg.close
    bora_cfg_path = bora_cfg.path
    cli = Bora::Cli.new([], {file: bora_cfg_path})
    capture do
      begin
        cli.invoke(cmd, params)
      rescue Exception => e
        puts e
      end
    end
  end
end

class BoraRake < BoraRunner
  def run(config, cmd, stack, *params)
    Rake.application = Rake::Application.new
    bora = Bora.new(config_file_or_hash: config)
    capture do
      Rake.application.instance_eval do
        bora.rake_tasks
        begin
          Rake.application["#{stack}:#{cmd}"].invoke(*params)
        rescue Exception => e
          puts e
        end
      end
    end
  end
end
