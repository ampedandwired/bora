require "thor"

class Bora
  class CliBase < Thor
    # Fix for incorrect subcommand help. See https://github.com/erikhuda/thor/issues/261
    def self.banner(command, namespace = nil, subcommand = false)
      "#{basename} #{subcommand_prefix} #{command.usage}"
    end

    no_commands do
      def stack(config_file, stack_name)
        region = options.region
        cfn_stack_name = options["cfn-stack-name"]

        override_config = {}
        override_config["default_region"] = region if region
        override_config["cfn_stack_name"] = cfn_stack_name if cfn_stack_name

        bora = bora(config_file, override_config)
        stack = bora.stack(stack_name)
        if !stack
          STDERR.puts "Could not find stack #{stack_name}"
          exit(1)
        end
        stack
      end

      def bora(config_file, override_config = {})
        Bora.new(config_file_or_hash: config_file, override_config: override_config)
      end

      def params
        options.params ? Hash[options.params.map { |param| param.split("=", 2) }] : {}
      end
    end
  end
end
