# Bora

This Ruby gem contains a command line utility and [rake](https://github.com/ruby/rake) tasks
that help you define and work with [CloudFormation](https://aws.amazon.com/cloudformation/) stacks.

In a single YAML file you define your templates,
the stack instances built from those templates (eg: dev, uat, staging, prod, etc),
and the parameters for those stacks. Parameters can even refer to outputs of other stacks.
Templates can be written with plain CloudFormation JSON or
[cfndsl](https://github.com/stevenjack/cfndsl).

Given this config, Bora then provides commands (or Rake tasks) to work with those stacks
(create, update, delete, diff, etc).


## Installation

If you're using Bundler, add this line to your application's `Gemfile`:

```ruby
gem 'bora'
```

And then run `bundle install`.

Alternatively, install directly with `gem install bora`.


## Quick Start

Create a file `bora.yml` in your project directory, something like this:
```yaml
templates:
  example:
    template_file: example.json
    stacks:
      uat:
        params:
          InstanceType: t2.micro
      prod:
        params:
          InstanceType: m4.xlarge
```

Now run `bora apply example-uat` to create your "uat" stack.
Bora will wait until the stack is complete (or failed),
and return stack events to you as they happen.
To get a full list of available commands, run `bora help`.

Alternatively if you prefer using Rake, add this to your `Rakefile`:

```ruby
require 'bora'
Bora.new.rake_tasks
```

Then run `rake example-uat:apply`.
To get a full list of available tasks run `rake -T`.


## File Format Reference

The example below is a `bora.yml` file showing all available options:

```yaml
# A map defining all the CloudFormation templates available.
# A "template" is effectively a single CloudFormation JSON (or cfndsl template).
templates:
  # A template named "app"
  app:
    # This template is a plain old CloudFormation JSON file
    template_file: app.json

    # Optional. An array of "capabilities" to be passed to the CloudFormation API
    # (see CloudFormation docs for more details)
    capabilities: [CAPABILITY_IAM]

    # A map defining all the "stacks" associated with this template
    # for example, "uat" and "prod"
    stacks:
      # The "uat" stack
      uat:
        # The CloudFormation parameters to pass into the stack
        params:
          InstanceType: t2.micro
          AMI: ami-11032472

      # The "prod" stack
      prod:
        # Optional. The stack name to use in CloudFormation
        # If you don't supply this, the name will be the template
        # name concatenated with the stack name as defined in this file,
        # eg: "app-prod".
        stack_name: prod-application-stack
        params:
          InstanceType: m4.xlarge
          AMI: ami-11032472

  # A template named "web"
  web:
    # This template is using cfndsl. Bora treats any template ending in
    # ".rb" as a cfndsl template.
    template_file: "web.rb"
    stacks:
      uat:
        # The CloudFormation parameters to pass into the stack.
        # You can define both cfndsl parameters and traditional CloudFormation
        # parameters here. Cfndsl will receive all of them, but only those
        # actually defined in the "Parameters" section of the template will be
        # passed through to CloudFormation when the stack is applied.
        params:
          dns_zone: example.com

          # You can use complex data structures with cfndsl parameters:
          users:
            - id: joe
              name: Joe Bloggs
            - id: mary
              name: Mary Bloggs

          # You can refer to outputs of other stacks using "${}" notation too.
          # See below for further details.
          app_url: http://${app-uat/outputs/Domain}/api

          # Traditional CloudFormation parameters
          InstanceType: t2.micro
          AMI: ami-11032472

      prod: {}
```

## Parameter Substitution

Bora supports looking up parameter values from other stacks and interpolating them into input parameters.
At present you can only look up the outputs of other stacks,
however in the future it may support looking up stack parameters or resources.
Other future possibilities include looking up values from other services,
for example AMI IDs.

The format is as follows:

`${<stack_name>/outputs/<output_name>}`

For example:
```yaml
params:
  api_url: http://${api-stack/outputs/Domain}/api
```

This will look up the `Domain` output from the stack named `api-stack` and substitute it into the `api_url` parameter.


## Command Reference

The following commands are available through the command line and rake tasks.

* **apply** - Creates the stack if it doesn't exist, or updates it otherwise
* **delete** - Deletes the stack
* **diff** - Provides a visual diff between the local template and the currently applied template in AWS
* **events** - Outputs the latest events from the stack
* **list** - Outputs a list of all stacks defined in the config file
* **outputs** - Shows the outputs from the stack
* **recreate** - Recreates (deletes then creates) the stack
* **show** - Shows the local template in JSON, generating it if necessary
* **show_current** - Shows the currently applied template in AWS
* **status** - Displays the current status of the stack
* **validate** - Validates the template using the AWS CloudFormation "validate" API call


## Command Line

Run `bora help` to see all available commands.

`bora help [command]` will show you help for a particular command,
eg: `bora help apply`.


## Rake Tasks

To use the rake tasks, simply put this in your `Rakefile`:
```ruby
require 'bora'
Bora.new.rake_tasks
```

To get a full list of available tasks run `rake -T`.


## Overriding Stack Parameters from the Command Line

Some commands accept a list of parameters that will override those defined in the YAML file.

If you are using the Bora command line, you can pass these parameters like this:

```bash
$ bora apply web-uat --params 'instance_type=t2.micro' 'ami=ami-11032472'
```

For rake, he equivalent is:
```bash
$ rake web-uat:apply[instance_type=t2.micro,ami=ami-11032472]
```


## Related Projects
The following projects provided inspiration for Bora:
* [CfnDsl](https://github.com/stevenjack/cfndsl) - A Ruby DSL for CloudFormation templates
* [CloudFormer](https://github.com/kunday/cloudformer) - Rake tasks for CloudFormation
* [Cumulus](https://github.com/cotdsa/cumulus) - A Python YAML based tool for working with CloudFormation


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ampedandwired/bora.
