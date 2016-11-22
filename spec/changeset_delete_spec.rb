require "helper/spec_helper"

describe BoraCli do
  let(:bora) { described_class.new }
  let(:stack) { setup_stack("web-prod", status: :created) }
  let(:bora_config) { default_config }

  it "deletes the given change set" do
    expect(stack).to receive(:delete_change_set).with("my-change-set")
    output = bora.run(bora_config, "changeset", "delete", "web-prod", "my-change-set")
  end

end
