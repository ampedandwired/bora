require "helper/spec_helper"

describe BoraCli do
  let(:bora) { described_class.new }
  let(:stack) { setup_stack("web-prod") }

  it "deletes the given change set" do
    expect(stack).to receive(:delete_change_set).with("my-change-set")
    output = bora.run(bora_config, "changeset", "delete", "web-prod", "my-change-set")
  end

  def bora_config
    config = {
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
end
