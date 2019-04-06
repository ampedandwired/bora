[![Gem](https://img.shields.io/gem/v/bora.svg)](https://rubygems.org/gems/bora)
[![Build Status](https://travis-ci.org/ampedandwired/bora.svg?branch=master)](https://travis-ci.org/ampedandwired/bora)

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

This gem requires Ruby 2.1 or greater.

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
# Optional. The default region for all stacks in the file.
# See below for further information.
default_region: us-east-1

# A map defining all the CloudFormation templates available.
# A "template" is effectively a single CloudFormation JSON (or cfndsl template).
templates:
  # A template named "app"
  app:
    # This template is a plain old CloudFormation JSON file
    template_file: app.json
    # Tag Key / Value pairs for the Cloudformation stack
    # Tags are inherited by stack resources
    tags:
      Name: my-app
    # Optional create stack parameters
    # See - http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Client.html#create_stack-instance_method
    capabilities: [CAPABILITY_IAM] # An array of "capabilities" to be passed to the CloudFormation API
    on_failure: DO_NOTHING # See CloudFormation API docs for valid values and their meanings; "disable_rollback" is also supported
    # Optional. The default region for all stacks in this template.
    # Overrides "default_region" at the global level.
    # See below for further information.
    default_region: us-west-2

    # A map defining all the "stacks" associated with this template
    # for example, "uat" and "prod"
    stacks:
      # The "uat" stack
      uat:

        params:
          InstanceType: t2.micro
          AMI: ami-11032472
      # The "prod" stack
      prod:
        # Overrides template level
        on_failure: DELETE
        # Tags here are merged with the template
        tags:
          Environment: uat
        # The CloudFormation parameters to pass into the stack
        # Optional. The stack name to use in CloudFormation
        # If you don't supply this, the name will be the template
        # name concatenated with the stack name as defined in this file,
        # eg: "app-prod".
        cfn_stack_name: prod-application-stack
        # Optional. Default region for this stack.
        # Overrides "default_region" at the template level.
        # See below for further information.
        default_region: ap-southeast-2
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
          app_url: http://${cfn://app-uat/outputs/Domain}/api

          # Traditional CloudFormation parameters
          InstanceType: t2.micro
          AMI: ami-11032472

      prod: {}
```

## Command Reference

The following commands are available through the command line and rake tasks.

* **apply** - Creates the stack if it doesn't exist, or updates it otherwise
* **changeset** - Manage CloudFormation change sets for the stack
* **delete** - Deletes the stack
* **diff** - Provides a visual diff between the local template and the currently applied template in AWS.
  The diff also shows the changes that CloudFormation will apply as reported by the CloudFormation [Change Set API](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html).
* **events** - Outputs the latest events from the stack
* **list** - Outputs a list of all stacks defined in the config file
* **outputs** - Shows the outputs from the stack
* **parameters** - Shows the parameters from the stack
* **recreate** - Recreates (deletes then creates) the stack
* **show** - Shows the local template in JSON, generating it if necessary
* **show_current** - Shows the currently applied template in AWS
* **status** - Displays the current status of the stack
* **validate** - Validates the template using the AWS CloudFormation "validate" API call

### Change Sets
Bora provides full support for working with [CloudFormation Change Sets](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html)
via the "changeset" command. The following subcommands are available (eg: `bora changeset <subcommand> ...`). Run `bora changeset help` for more information.

* **changeset create** - Creates a change set for the stack
* **changeset list** - Lists all available change sets for the stack
* **changeset show** - Shows the details of a particular change set
* **changeset apply** - Applies a change set. Any other available change sets will be automatically deleted by AWS after this action.
* **changeset delete** - Deletes a particular change set for the stack

Note that `bora diff` will also show you a summary of the change set that will be applied.
It does this by creating (and automaticlly deleting) a temporary change set in order to get the change actions to display.

Note that change set funtionality is not available via the Rake tasks at this time.

### Command Line

Run `bora help` to see all available commands.

`bora help [command]` will show you help for a particular command,
eg: `bora help apply`.


### Rake Tasks

To use the rake tasks, simply put this in your `Rakefile`:
```ruby
require 'bora'
Bora.new.rake_tasks
```

To get a full list of available tasks run `rake -T`.


## Specifying Regions
You can specify the region in which to create a stack in a few ways.
The order of precedence is as follows (first non-empty value found wins):

- The `--region` parameter on the command line (only available in the CLI, not in the Rake tasks)
- The `default_region` setting within the stack section in `bora.yml`
- The `default_region` setting within the template section in `bora.yml`
- The `default_region` setting at the top level of `bora.yml`
- The [default region as determined by the AWS Ruby SDK](https://docs.aws.amazon.com/sdkforruby/api/index.html).


## Parameter Substitution

Bora supports looking up parameter values from various locations and interpolating them into stack parameters.
This is useful so that you don't have to hard-code values into your stack parameters that may change across regions or over time.
For example, you might have a VPC template that creates a subnet and returns the subnet ID as a stack output.
You could then have an application template that creates an EC2 instance in that subnet,
with the subnet ID parameter looked up dynamically from the VPC stack.

These lookup parameters are specified using `${}` syntax within the parameter value,
and the lookup target is a URI.

For example:

```yaml
params:
  api_url: http://${cfn://api-stack/outputs/Domain}/api
```

This will look up the `Domain` output from the stack named `api-stack` and substitute it into the `api_url` parameter.
The URI "scheme" (`cfn` in the above example) controls which resolver will handle the lookup.
The format of the rest of the URI is dependent on the resolver.

There are a number of resolvers that come with Bora (documented below),
or you can write your own.


### Parameter Lookup
Any substitution that does not specify a "scheme" is treated as a reference to another parameter value.
For example:

```yaml
params:
  domain: example.com
  url: http://${domain}/foo
```

This even works within array or hash parameters,
although you can only look up values from the top level params.

```yaml
params:
  domain: example.com
  site_config:
    url: http://${domain}/foo
```


### Stack Output Lookup

You can look up outputs from stacks in the same region.

For example:
```bash
# Look up output "MyOutput" from stack "my-stack" in the same region as the current stack.
${cfn://my-stack/outputs/MyOutput}

# Look up an output from a stack in another region
${cfn://my-stack.ap-southeast-2/outputs/MyOutput}
```


### CredStash Key Lookup
[CredStash](https://github.com/fugue/credstash) is a utility for storing secrets using AWS KMS.
You can pass these secrets as parameters to your stack.
If you do so, you should use a CloudFormation parameter with the ["NoEcho" flag](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html) to true,
so as to not expose the secret in the template.

For example:
```bash
# Simple key lookup in same region as the stack. Note 3 slashes. Will run `credstash get mykey`.
${credstash:///mykey}

# Lookup with a key context. Will run `credstash get mykey app=webapp`.
${credstash:///mykey?app=webapp}

# Lookup a credstash in another region.
${credstash://ap-southeast-2/mykey?app=webapp}
```


### Route53 Hosted Zone ID Lookup
Looks up the Route53 hosted zone ID given a hosted zone name (eg: example.com).
Also allows you to specify if you want the private or public hosted zone for a given name,
which can be useful if you have set up split-view DNS with both public and private zones for the same name.

```bash
${hostedzone://example.com}
${hostedzone://example.com/public}
${hostedzone://example.com/private}
```
### AMI Lookup

Looks up an AMI given a name prefix which may contain wildcards. If query returns multiple images the latest is used.

Owners takes a query string list of AWS account ID, self (owner is the sender of the request), or an AWS owner alias (valid values are amazon | aws-marketplace | microsoft). Omitting this option defaults to self

```bash
${ami://amzn-ami-hv*x86_64-gp2?owner=amazon}
${ami://my-windows-soe}
${ami://my-windows-soe?owner=1234567890,self}
```

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


## Creating Multiple Instances of a Stack
Sometimes it can be useful to create multiple instances of a single stack.
For example, you may define a single "qa" stack with all the settings for a testing environment.
Then you might want to stand up this stack multiple times so you can have multiple testing environments,
eg "qa1", "qa2", etc.

Bora makes this possible by allowing you to override the name of the stack that gets created in CloudFormation.
For example:

```bash
$ bora apply web-qa --cfn-stack-name "web-qa-1"
$ bora apply web-qa --cfn-stack-name "web-qa-2"
```

Remember that if you use this functionality you must remember to pass in the stack name to *every* command or you will get unexepected results.

```bash
$ bora outputs web-qa --cfn-stack-name "web-qa-1"
```

Work is underway to improve how Bora handles this use case.
If this is of interest to you, please have a look at the [GitHub issue](https://github.com/ampedandwired/bora/issues/10) for this functionality.


## Related Projects
The following projects provided inspiration for or are similar to Bora.
If Bora doesn't meet your needs, one of these might.
* [CfnDsl](https://github.com/cfndsl/cfndsl) - A Ruby DSL for CloudFormation templates
* [StackMaster](https://github.com/envato/stack_master) - Very similar in goals to Bora
* [CloudFormer](https://github.com/kunday/cloudformer) - Rake tasks for CloudFormation
* [Cumulus](https://github.com/cotdsa/cumulus) - A Python YAML based tool for working with CloudFormation


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ampedandwired/bora.
