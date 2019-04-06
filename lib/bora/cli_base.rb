require 'thor'

class Bora
  class CliBase < Thor
    # Fix for incorrect subcommand help. See https://github.com/erikhuda/thor/issues/261
    def self.banner(command, _namespace = nil, subcommand = false)
      # rubocop:disable Lint/ShadowedArgument
      subcommand = subcommand_prefix
      # rubocop:enable Lint/ShadowedArgument
      subcommand_str = subcommand ? " #{subcommand}" : ''
      "#{basename}#{subcommand_str} #{command.usage}"
    end

    def self.subcommand_prefix
      nil
    end

    no_commands do
      def stack(config_file, stack_name)
        region = options.region
        cfn_stack_name = options['cfn-stack-name']

        override_config = {}
        override_config['default_region'] = region if region
        override_config['cfn_stack_name'] = cfn_stack_name if cfn_stack_name

        bora = bora(config_file, override_config)
        stack = bora.stack(stack_name)
        unless stack
          warn "Could not find stack #{stack_name}"
          exit(1)
        end
        stack
      end

      def bora(config_file, override_config = {})
        Bora.new(config_file_or_hash: config_file, override_config: override_config)
      end

      def params
        options.params ? Hash[options.params.map { |param| param.split('=', 2) }] : {}
      end
    end
  end
end
