require 'rake'
require 'helper/spec_helper'
require 'apply_examples'
require 'delete_examples'
require 'diff_examples'
require 'events_examples'
require 'outputs_examples'
require 'parameters_examples'
require 'recreate_examples'
require 'show_examples'
require 'show_current_examples'
require 'status_examples'
require 'validate_examples'

shared_examples 'bora' do
  let(:bora) { described_class.new }

  before do
    @config = {
      "templates" => {
        "web" => {
          "template_file" => File.join(__dir__, "fixtures/web_template.json"),
          "stacks" => {
            "prod" => {}
          }
        }
      }
    }
  end

  include_examples "bora#apply"
  include_examples "bora#delete"
  include_examples "bora#diff"
  include_examples "bora#events"
  include_examples "bora#outputs"
  include_examples "bora#parameters"
  include_examples "bora#recreate"
  include_examples "bora#show"
  include_examples "bora#show_current"
  include_examples "bora#status"
  include_examples "bora#validate"
end


describe BoraCli do
  it_behaves_like 'bora'
end

describe BoraRake do
  it_behaves_like 'bora'
end
