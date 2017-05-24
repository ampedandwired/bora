require 'hashie'
require 'rake'
require 'bora/cli'

DEFAULT_REGION = 'us-stubbed-1'.freeze

def setup_stack(stack_name, status: :not_created, outputs: nil)
  stack = double(Bora::Cfn::Stack)
  allow(Bora::Cfn::Stack).to receive(:new).with(stack_name, DEFAULT_REGION).and_return(stack)
  allow(stack).to receive(:region).and_return(DEFAULT_REGION)

  if status == :not_created
    allow(stack).to receive(:status).and_return(Bora::Cfn::StackStatus.new(nil))
    allow(stack).to receive('exists?').and_return(false)
  else
    underlying_stack = Hashie::Mash.new
    underlying_stack.stack_status = status.to_s.upcase
    underlying_stack.stack_name = stack_name
    allow(stack).to receive(:status).and_return(Bora::Cfn::StackStatus.new(underlying_stack))
    allow(stack).to receive('exists?').and_return(true)
  end

  if outputs
    setup_outputs(stack, outputs)
  else
    allow(stack).to receive(:outputs).and_return(nil)
  end

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

def setup_events(stack, events)
  bora_events = events.map { |e| Bora::Cfn::Event.new(Aws::CloudFormation::Types::StackEvent.new(e)) }
  expect(stack).to receive(:events).and_return(bora_events)
end

def setup_create_change_set(stack, change_set_name, change_set)
  cfn_change_set_result = Hashie::Mash.new(change_set.merge(change_set_name: change_set_name))
  bora_change_set = Bora::Cfn::ChangeSet.new(cfn_change_set_result)
  if change_set_name
    allow(stack).to receive(:create_change_set).with(change_set_name, anything).and_return(bora_change_set)
  else
    allow(stack).to receive(:create_change_set).with(any_args).and_return(bora_change_set)
  end
  bora_change_set
end

def setup_change_sets(stack, change_sets)
  bora_change_sets = change_sets.map { |cs| Bora::Cfn::ChangeSet.new(Hashie::Mash.new(cs), true) }
  allow(stack).to receive(:list_change_sets).and_return(bora_change_sets)
  bora_change_sets
end

def setup_template(bora_config, template_name, template)
  # Use a class variable to ensure ruby doesn't GC and delete the temp file until the spec is complete
  @_temp_template_file = Tempfile.new(['bora_template', '.yaml'])
  template = template.to_json if template.is_a?(Hash) || template.is_a?(Array)
  @_temp_template_file.write(template)
  @_temp_template_file.close
  template_path = @_temp_template_file.path
  bora_config['templates'][template_name]['template_file'] = template_path
  template_path
end

def default_config(overrides = {})
  Hashie::Mash.new(
    'templates' => {
      'web' => {
        'template_file' => File.join(__dir__, '../fixtures/web_template.json'),
        'stacks' => {
          'prod' => {}
        }
      }
    }
  ).deep_merge(overrides)
end

class BoraCli
  def capture
    stream = StringIO.new
    $stdout = stream
    $stderr = stream
    begin
      yield
    ensure
      result = stream.string
      $stdout = STDOUT
      $stderr = STDERR
    end

    # puts result
    result
  end

  def run(config, *params, expect_exception: false)
    bora_cfg = Tempfile.new(['bora', '.yaml'])
    if config.is_a?(Hashie::Mash)
      config = config.to_hash
    end
    bora_cfg.write(config.to_yaml)
    bora_cfg.close
    bora_cfg_path = bora_cfg.path
    thor_args = params + ['--file', bora_cfg_path]
    String.disable_colorization = true
    capture do
      begin
        Bora::Cli.start(thor_args)
      rescue StandardError => e
        puts e
        puts e.backtrace
        raise e unless expect_exception
      end
    end
  end
end
