# Bora

This gem contains Ruby [rake](https://github.com/ruby/rake) tasks that help you work with [CloudFormation](https://aws.amazon.com/cloudformation/) stacks.
You don't need to use it with rake though - you can use the underlying classes in any Ruby app.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bora'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bora

## Usage

### Quick Start

Add this to your `Rakefile`

```ruby
require 'bora'

Bora::Tasks.new("example", "example.json")
```

This will give you the following rake tasks

```shell
rake stack:example:apply             # Creates (or updates) the 'example' stack
rake stack:example:delete            # Deletes the 'example' stack
rake stack:example:diff              # Diffs the new template with the 'example' stack's current template
rake stack:example:events            # Outputs the latest events from the 'example' stack
rake stack:example:outputs           # Shows the outputs from the 'example' stack
rake stack:example:recreate          # Recreates (deletes then creates) the 'example' stack
rake stack:example:show              # Shows the new template for 'example' stack
rake stack:example:show_current      # Shows the current template for 'example' stack
rake stack:example:status            # Displays the current status of the 'example' stack
rake stack:example:validate          # Checks the 'example' stack's template for validity
```

You can add as many templates as you like into your Rakefile, simply define an instance of `Bora::Tasks` for each one.

### Task Options

When you define the Bora tasks, you can pass in a number of options that control how Bora works and what gets passed to CloudFormation.
The available options are shown below with their default values.

```ruby
Bora::Tasks.new("example", "example.json") do |t|
  t.stack_options = {}
  t.colorize = true
end
```
* `example.json` - this is a URL to your template. It can be anything openable by Ruby's [`open-uri`](http://ruby-doc.org/stdlib-2.3.0/libdoc/open-uri/rdoc/OpenURI.html) library (eg: a local file or http/https URL), or an `s3://` URL. This parameter is optional - if you don't supply it, you *must* specify either `template_body` or `template_url` in the `stack_options` (see below).
* `stack_options` - A hash of options that are passed directly to the CloudFormation [`create_stack`](http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Client.html#create_stack-instance_method) and [`update_stack`](http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Client.html#update_stack-instance_method) APIs. If you specified a template URL in the constructor you don't need to supply `template_body` or `template_url here (you will get an error if you do).
* `colorize` - A boolean that controls whether console output is colored or not


### Dynamically Generated Templates
If you are generating your templates dynamically using a DSL such as [cfndsl](https://github.com/stevenjack/cfndsl) you can easily hook this into the Bora tasks by defining a `generate` task within the Bora::Tasks constructor.

```ruby
Bora::Tasks.new("example", "example.json") do |t|
  desc "Generates the template"
  task :generate do
    # Generate your template and write it into "example.json" here
  end
end
```

`cfndsl` comes with a rake task that you can use by embedding it inside the Bora task definition:

```ruby
require 'bora'
require 'cfndsl/rake_task'

Bora::Tasks.new("example", "example.json") do |t|
  CfnDsl::RakeTask.new do |cfndsl_task|
    cfndsl_task.cfndsl_opts = {
      files: [{
        filename: "example.rb",
        output: "example.json"
      }]
    }
  end
end
```

If you need to pass parameters from the rake command line through to your generate method,
you can do so by using Rake's [`args.extras`](http://ruby-doc.org/stdlib-2.2.2/libdoc/rake/rdoc/Rake/TaskArguments.html#method-i-extras) functionality:

```ruby
Bora::Tasks.new("example", "example.json") do |t|
  task :generate do |t, args|
    arg1, arg2 = args.extras
    # Generate your template and write it into "example.json" here
  end
end
```
```shell
$ rake stack:example:apply[arg1_value, arg2_value]
```


### API

You can use this gem without using Rake. Most of the logic is implemented in [stack.rb](https://github.com/ampedandwired/bora/blob/master/lib/bora/stack.rb) and is fairly self-explanatory.

```ruby
require 'bora'

stack = Bora::Cfn::Stack.new("my-stack")
result = stack.update({template_body: File.read("example.json")}) do |event|
  puts event
end

puts "Update #{result ? "succeeded" : "failed"}"
```

### YAML Configuration - Experimental
You can define and configure your stacks through YAML too.
This interface is currently experimental,
but longer term is likely to become the primary way to use this gem.
Sample usage is shown below (subject to change).

Rakefile:
```ruby
require "bora"
Bora::RakeTasks.new('templates.yml')
```

templates.yml:
```yaml
templates:
  app:
    template_file: templates/test.json
    stacks:
      dev: {}
      uat: {}

  web:
    # Templates ending in ".rb" are treated as cfndsl templates
    template_file: templates/test.rb
    capabilities: [CAPABILITY_IAM]
    stacks:
      dev:
        # Set stack name explicitly (otherwise would default to "web-dev")
        stack_name: foo-dev
        params:
          # Look up a value from the outputs of the "app-dev"stack
          app_sg: ${app-dev/outputs/AppSecurityGroup}
      uat:
        params:
          app_sg: foouatdev

```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ampedandwired/bora.
