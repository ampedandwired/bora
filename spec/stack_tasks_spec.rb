require "helper/spec_helper"

describe Bora::StackTasks do
  STACK_NAME = "web-prod"

  before do
    @stack = double(Bora::Stack)
    allow(@stack).to receive(:stack_name).and_return(STACK_NAME)
    Rake.application = Rake::Application.new
    Rake.application.instance_exec(@stack) do |stack|
      Bora::StackTasks.new(stack)
    end
  end

  describe "#apply" do
    it "invokes stack apply" do
      expect(@stack).to receive(:apply)
      invoke_rake("apply")
    end

    it "allows override params to be passed in" do
      expect(@stack).to receive(:apply).with({
        "foo" => "bar",
        "bing" => "",
        "baz" => "x=y"
      })
      invoke_rake("apply", "foo=bar", "bing=", "baz=x=y")
    end
  end

  describe "#delete" do
    it "invokes stack delete" do
      expect(@stack).to receive(:delete)
      invoke_rake("delete")
    end
  end

  describe "#diff" do
    it "invokes stack diff" do
      expect(@stack).to receive(:diff).with({"foo" => "bar"})
      invoke_rake("diff", "foo=bar")
    end
  end

  describe "#events" do
    it "invokes stack events" do
      expect(@stack).to receive(:events)
      invoke_rake("events")
    end
  end

  describe "#outputs" do
    it "invokes stack outputs" do
      expect(@stack).to receive(:outputs)
      invoke_rake("outputs")
    end
  end

  describe "#status" do
    it "invokes stack status" do
      expect(@stack).to receive(:status)
      invoke_rake("status")
    end
  end

  describe "#recreate" do
    it "invokes stack recreate" do
      expect(@stack).to receive(:recreate).with({"foo" => "bar"})
      invoke_rake("recreate", "foo=bar")
    end
  end

  describe "#show" do
    it "invokes stack show" do
      expect(@stack).to receive(:show).with({"foo" => "bar"})
      invoke_rake("show", "foo=bar")
    end
  end

  describe "#show_current" do
    it "invokes stack show_current" do
      expect(@stack).to receive(:show_current)
      invoke_rake("show_current")
    end
  end

  describe "#status" do
    it "invokes stack status" do
      expect(@stack).to receive(:status)
      invoke_rake("status")
    end
  end

  describe "#validate" do
    it "invokes stack validate" do
      expect(@stack).to receive(:validate).with({"foo" => "bar"})
      invoke_rake("validate", "foo=bar")
    end
  end


  def invoke_rake(cmd, *params)
    Rake.application["#{STACK_NAME}:#{cmd}"].invoke(*params)
  end

end
