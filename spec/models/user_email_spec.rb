require 'spec_helper'

describe User do

  describe "email" do

    it "allows the email with plus" do
      email = "firstname.lastname+foobar@googlemail.com"
      user = UserFactory.create_new
      user.username = "hanz"
      user.email = email
      user.save.should be_true
      user_db_1 = User.find_by_username("hanz")
      user_db_1.should_not be_nil
      user_db_2 = User.find_by_email(email)
      user_db_2.should_not be_nil
    end

    it "allows the email with plus" do
      user = UserFactory.create_new
      user.email = "hans+banz@tanz.de"
      user.save.should be_true
    end

    it "allows the email with plus" do
      user = UserFactory.create_new
      user.email = "hans+banz@tanzfranz.de"
      user.save.should be_true
    end

    it "allows the email with plus" do
      user = UserFactory.create_new
      user.username = "joschi"
      user.email = "jochen+versioneye@schalanda.name"
      user.save.should be_true
      user_db_1 = User.find_by_username("joschi")
      user_db_1.should_not be_nil
      user_db_2 = User.find_by_email("jochen\+versioneye@schalanda.name")
      user_db_2.should_not be_nil
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
