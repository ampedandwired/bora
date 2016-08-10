require "helper/spec_helper"

describe BoraCli do
  let(:bora) { described_class.new }

  before do
    @config = {
      "templates" => {
        "web" => {
          "template_file" => "web_template.json",
          "stacks" => {
            "dev" => {},
            "prod" => {}
          }
        },
        "app" => {
          "template_file" => "app_template.json",
          "stacks" => {
            "dev" => {},
            "prod" => {}
          }
        }
      }
    }
  end

  it "lists all available stacks" do
    output = bora.run(@config, "list")
    expect(output).to include("web-dev", "web-prod", "app-dev", "app-prod")
  end

end
