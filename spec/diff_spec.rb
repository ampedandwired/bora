require "helper/spec_helper"

describe BoraCli do
  let(:bora) { described_class.new }
  before do
    @stack = setup_stack("web-prod", status: :create_complete)
    setup_parameters(@stack, [])
  end

  it "shows a configurable number of context lines around each diff" do
    current_template = "line1\nline2\nline3\nline4\nline5\nline6\nline7\nline8\nline9\nlineA\nlineB\nlineC\nlineD\nlineE"
    new_template     = "line1\nline2\nline3\nline4\nline5\nline6\nline7\nline88\nline9\nlineA\nlineB\nlineC\nlineD\nlineE"
    expect(@stack).to receive(:template).and_return(current_template)
    expect(@stack).to receive(:new_template).and_return(new_template)
    output = bora.run(bora_config, "diff", "web-prod", "--context", "5")
    expect(output).not_to include("line2")
    expect(output).to include("line3")
    expect(output).to include("-line8")
    expect(output).to include("+line88")
    expect(output).to include("lineD")
    expect(output).not_to include("lineE")
  end

  def bora_config
    {
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
