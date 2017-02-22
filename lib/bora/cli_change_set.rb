require 'thor'
require 'thor/group'

class Bora
  class CliChangeSet < CliBase
    # Fix for incorrect subcommand help. See https://github.com/erikhuda/thor/issues/261
    def self.subcommand_prefix
      'changeset'
    end

    desc 'create STACK_NAME CHANGE_SET_NAME', 'Creates a change set'
    option :params, type: :array, aliases: :p, desc: "Parameters to be passed to the template, eg: --params 'instance_type=t2.micro'"
    option :description, type: :string, aliases: :d, desc: 'A description for this change set'
    option :pretty, type: :boolean, default: false, desc: 'Send pretty (formatted) JSON to AWS (only works for cfndsl templates)'
    def create(stack_name, change_set_name)
      stack(options.file, stack_name).create_change_set(change_set_name, options.description, params, options.pretty)
    end

    desc 'list STACK_NAME', 'Lists all change sets for stack STACK_NAME'
    def list(stack_name)
      stack(options.file, stack_name).list_change_sets
    end

    desc 'show STACK_NAME CHANGE_SET_NAME', 'Shows the details of the named change set'
    def show(stack_name, change_set_name)
      stack(options.file, stack_name).describe_change_set(change_set_name)
    end

    desc 'delete STACK_NAME CHANGE_SET_NAME', 'Deletes the named change set'
    def delete(stack_name, change_set_name)
      stack(options.file, stack_name).delete_change_set(change_set_name)
    end

    desc 'apply STACK_NAME CHANGE_SET_NAME', 'Executes the named change set'
    def apply(stack_name, change_set_name)
      stack(options.file, stack_name).execute_change_set(change_set_name)
    end
  end
end
