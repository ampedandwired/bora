require "helper/spec_helper"

describe BoraCli do
  let(:bora) { described_class.new }
  let(:stack) { setup_stack("web-prod") }

  it "shows the given change set" do
    change_set_name = "test-change-set"
    change_set = setup_create_change_set(stack, change_set_name, {
      status: "CREATE_COMPLETE",
      status_reason: "Finished",
      execution_status: "AVAILABLE",
      description: "My change set",
      creation_time: Time.parse("2016-07-21 15:01:00"),
      changes: [
        {
          resource_change: {
            action: "Modify",
            resource_type: "AWS::EC2::SecurityGroup",
            logical_resource_id: "MySG"
          }
        }
      ]
    })

    expect(stack).to receive(:describe_change_set).with(change_set_name).and_return(change_set)
    output = bora.run(bora_config, "changeset", "show", "web-prod", change_set_name)
    expect(output).to include(change_set_name)
    expect(output).to include("CREATE_COMPLETE")
    expect(output).to include("AVAILABLE")
    expect(output).to include("2016-07-21 15:01:00")
    expect(output).to include("Modify")
    expect(output).to include("AWS::EC2::SecurityGroup")
    expect(output).to include("MySG")
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
