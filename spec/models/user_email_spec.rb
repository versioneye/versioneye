require 'spec_helper'

describe User do

  describe "email" do

    it "allows the email with plus" do
      user = UserFactory.create_new
      user.email = "hans@tanz.de"
      user.save.should be_true
    end

    it "allows the email with plus" do
      user = UserFactory.create_new
      user.email = "hans+banz@tanz.de"
      user.save.should be_true
    end

    it "doesnt save because incorrect email" do
      user = UserFactory.create_new
      user.email = "hans@tanz"
      user.save.should be_false
    end

    it "doesnt save because incorrect email" do
      user = UserFactory.create_new
      user.email = "@tanz.de"
      user.save.should be_false
    end

    it "doesnt save because incorrect email" do
      user = UserFactory.create_new
      user.email = "hans-tanz.de"
      user.save.should be_false
    end

  end

end
