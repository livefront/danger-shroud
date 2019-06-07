require File.expand_path("../spec_helper", __FILE__)

module Danger
  describe Danger::DangerShroud do
    it "should be a plugin" do
      expect(Danger::DangerShroud.new(nil)).to be_a Danger::Plugin
    end

    #
    # TODO test your custom attributes and methods here
    #
  end
end