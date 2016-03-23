require 'colorize'
require 'rake/tasklib'
require 'bora/stack'
require 'bora/tasks'

module Bora
  class StackTasks < Rake::TaskLib
    def initialize(config)
      config['templates'].each do |template_name, template_config|
        template_file = template_config['template_file']
        template_config['stacks'].each do |stack_name, stack_config|
          stack_name = stack_config['stack_name'] || "#{template_name}-#{stack_name}"
          Bora::Tasks.new(stack_name, template_file) do |t|
          end
        end
      end
    end
  end
end
