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

Bora::Tasks.new("example") do |t|
  t.stack_options = {
    template_body: File.read("example.json")
  }
end
```

This will give you the following rake tasks

```shell
rake stack:example:apply             # Creates (or updates) the 'example' stack
rake stack:example:current_template  # Shows the current template for 'example' stack
rake stack:example:delete            # Deletes the 'example' stack
rake stack:example:diff              # Diffs the new template with the 'example' stack's current template
rake stack:example:events            # Outputs the latest events from the 'example' stack
rake stack:example:new_template      # Shows the new template for 'example' stack
rake stack:test:outputs              # Shows the outputs from the 'example' stack
rake stack:example:recreate          # Recreates (deletes then creates) the 'example' stack
rake stack:example:status            # Displays the current status of the 'example' stack
rake stack:example:validate          # Checks the 'example' stack's template for validity
```

You can add as many templates as you like into your Rakefile, simply define an instance of `Bora::Tasks` for each one.

### Task Options

When you define the Bora tasks, you can pass in a number of options that control how Bora works and what gets passed to CloudFormation.
The available options are shown below with their default values.

```ruby
Bora::Tasks.new("example") do |t|
  t.colorize = true
  t.stack_options = {}
end
```

* `colorize` - A boolean that controls whether console output is colored or not
* `stack_options` - A hash of options that are passed directly to the CloudFormation [create_stack](http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Client.html#create_stack-instance_method) and [update_stack](http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Client.html#update_stack-instance_method) APIs.
  You must at a minimum specify either the `template_body` or `template_url` option.


### API

You can use this gem without using Rake. Most of the logic is implemented in [stack.rb](https://github.com/ampedandwired/bora/blob/master/lib/bora/stack.rb) and is fairly self-explanatory.

```ruby
require 'bora'

stack = Bora::Stack.new("my-stack")
result = stack.update({template_body: File.read("example.json")}) do |event|
  puts event
end

puts "Update #{result ? "succeeded" : "failed"}"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ampedandwired/bora.
