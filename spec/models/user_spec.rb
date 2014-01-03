require 'spec_helper'

describe User do

  let(:github_user) { FactoryGirl.create(:github_user)}
  let(:twitter_user){ FactoryGirl.create(:twitter_user)}

  before(:each) do
    User.destroy_all
    UserFactory.create_defaults
  end

  describe "to_param" do
    it "returns username as default param" do
      github_user.username = "hanstanz"
      github_user.to_param.should eq('hanstanz')
    end
  end

  describe "create_verification" do
    it "generates a verification string" do
      github_user.verification.should be_nil
      github_user.create_verification
      github_user.verification.should_not be_nil
    end
  end

  describe "activate!" do
    it "activates a user" do
      github_user.create_verification
      github_user.save
      verification = github_user.verification
      verification.should_not be_nil
      verification.size.should be > 2
      User.activate!(verification)
      user = User.find(github_user.id)
      user.should_not be_nil
      user.verification.should be_nil
    end
  end

  describe "activated?" do
    it "tests the activated? method" do
      github_user.create_verification
      github_user.verification.should_not be_nil
      github_user.activated?.should be_false
      github_user.verification = nil
      github_user.activated?.should be_true
    end
  end

  describe "activate!" do
    it "tests the activated? method" do
      email = "hans1@tanz.de"
      github_user.fullname = "Hans1 Tanz"
      github_user.username = "hanstanz1"
      github_user.email = email
      github_user.password = "password"
      github_user.salt = "salt"
      github_user.create_verification
      github_user.save

      db_user = User.find_by_email( email )
      db_user.should_not be_nil
      db_user.verification.should_not be_nil
      db_user.activated?.should be_false
      User.activate!(github_user.verification)

      db_user2 = User.find_by_email( email )
      db_user2.verification.should be_nil
      db_user2.activated?.should be_true
    end
  end

  describe "save" do
    it "saves a new user in the db" do
      email = "h+ans2@tanz.de"
      user = User.new
      user.fullname = "Hans Tanz"
      user.username = "hanstanz2"
      user.email = email
      user.password = "password"
      user.salt = "salt"
      user.terms = true
      user.datenerhebung = true
      user.save.should be_true
      db_user = User.find_by_email( email )
      db_user.should_not be_nil
      user.remove
    end
    it "saves a new user in the db" do
      email = "daniele.sluijters+versioneye@gmail.com"
      user = User.new
      user.fullname = "Daniele sluijters"
      user.username = "sluijters"
      user.email = email
      user.password = "password"
      user.salt = "salt"
      user.terms = true
      user.datenerhebung = true
      user.save.should be_true
      db_user = User.find_by_email( email )
      db_user.should_not be_nil
      user.remove
    end
    it "test case for tobias" do
      email = "t@blinki.st"
      user = User.new
      user.fullname = "Tobias"
      user.username = "blinki"
      user.email = email
      user.password = "password"
      user.salt = "salt"
      user.terms = true
      user.datenerhebung = true
      user.save
      db_user = User.find_by_email( email )
      db_user.should_not be_nil
      db_user.remove
    end
    it "dosn't save. Because username is unique" do
      email = "h+ans+2@ta+nz.de"
      user = User.new
      user.fullname = "Hans Tanz"
      user.username = "hanstanz"
      user.email = email
      user.password = "password"
      user.salt = "salt"
      user.terms = true
      user.datenerhebung = true
      user.save.should be_false
      db_user = User.find_by_email( email )
      db_user.should be_nil
      user.remove
    end
    it "dosn't save. Because email is unique" do
      github_user
      email = "hans@tanz.de"
      user = User.new
      user.fullname = "Hans Tanz"
      user.username = "hanstanz55"
      user.email = email
      user.password = "password"
      user.salt = "salt"
      user.terms = true
      user.datenerhebung = true
      user.save.should be_false
      user.remove
    end
    it "dosn't save. Because email is not valid" do
      email = "hans@tanz"
      user = User.new
      user.fullname = "Hans Tanz"
      user.username = "hanstanz5gasg"
      user.email = email
      user.password = "password"
      user.salt = "salt"
      user.terms = true
      user.datenerhebung = true
      save = user.save
      save.should be_false
      db_user = User.find_by_email( email )
      db_user.should be_nil
      user.remove
    end
  end

  describe "has_password?" do
    it "doesn't have the password" do
      github_user.has_password?("agfasgasfgasfg").should be_false
    end
    it "does have the password" do
      github_user.has_password?("password").should be_true
    end
  end

  describe "find_by_email" do
    it "returns nil for nil" do
      User.find_by_email(nil).should be_nil
    end
    it "returns nil for empty string" do
      User.find_by_email("   ").should be_nil
    end
    it "doesn't find by email" do
      User.find_by_email("agfasgasfgasfg").should be_nil
    end
    it "does find by email" do
      github_user
      user = User.find_by_email("hans@tanz.de")
      user.should_not be_nil
      user.email.eql?(github_user.email).should be_true
      user.id.eql?(github_user.id).should be_true
    end
  end

  describe "find_by_username" do
    it "doesn't find by username" do
      User.find_by_username("agfasgasfgasfg").should be_nil
    end
    it "does find by username" do
      github_user
      user = User.find_by_username("hans_tanz")
      user.should_not be_nil
      user.username.eql?(github_user.username).should be_true
      user.id.eql?(github_user.id).should be_true
    end
  end

  describe "find_by_github_id" do
    it "doesn't find by github id" do
      User.find_by_github_id("agfgasasgasfgasfg").should be_nil
    end
    it "returns nil for nil" do
      User.find_by_github_id( nil ).should be_nil
    end
    it "returns nil for empty string" do
      User.find_by_github_id( "   " ).should be_nil
    end
    it "does find by github_id" do
      github_user
      user = User.find_by_github_id("github_id_123")
      user.should_not be_nil
      user.github_id.eql?(github_user.github_id).should be_true
      user.id.eql?(github_user.id).should be_true
    end
  end

  describe "find_by_twitter_id" do
    it "doesn't find by twitter id" do
      User.find_by_twitter_id("agfgasasgasfgasfg").should be_nil
    end
    it "returns nil for nil" do
      User.find_by_twitter_id( nil ).should be_nil
    end
    it "returns nil for empty string" do
      User.find_by_twitter_id( "   " ).should be_nil
    end
    it "does find by twitter_id" do
      twitter_user
      user = User.find_by_twitter_id("twitter_id_123")
      user.should_not be_nil
      user.twitter_id.eql?(twitter_user.twitter_id).should be_true
      user.id.eql?(twitter_user.id).should be_true
    end
  end

  describe "authenticate" do
    it "doesn't authenticate" do
      User.authenticate("agfasgasfgasfg", "agsasf").should be_nil
    end
    it "does authenticate" do
      github_user
      user = User.authenticate("hans@tanz.de", "password")
      user.should_not be_nil
      user.id.eql?(github_user.id).should be_true
    end
  end

  describe "authenticate_with_salt" do
    it "doesn't authenticate" do
      User.authenticate_with_salt(33333, "agsasf").should be_nil
    end
    it "does authenticate" do
      user = User.authenticate_with_salt(github_user.id, github_user.salt)
      user.should_not be_nil
      user.id.eql?(github_user.id).should be_true
    end
  end

  describe "username_valid?" do
    it "is not" do
      User.username_valid?("agsasf").should be_true
    end
    it "is" do
      User.username_valid?(github_user.username).should be_false
    end
  end

  describe "email_valid?" do
    it "is not" do
      User.email_valid?("agsasf").should be_true
    end
    it "is not because it is in email_user" do
      user_email = UserEmail.new
      user_email.email = "tada@hoplaho.de"
      user_email.user_id = github_user.id.to_s
      user_email.save
      User.email_valid?(user_email.email).should be_false
      user_email.remove
    end
    it "is" do
      User.email_valid?(github_user.email).should be_false
    end
  end

  describe "reset_password" do
    it "does reset the password" do
      password = String.new github_user.password
      user = User.authenticate(github_user.email, password)
      user.should_not be_nil
      user.reset_password
      user.password.should_not eql(password)
      user.verification.should_not be_nil
    end
  end

  describe "update_password" do
    it "does not update the password" do
      github_user.update_password("passwordasg", "asgasgfs").should be_false
    end
    it "does update the password" do
      github_user.reset_password
      github_user.update_password(github_user.verification, "newpassword").should be_true
      user = User.authenticate(github_user.email, "newpassword")
      user.should_not be_nil
    end
  end

  describe "create_username" do

    it "does create a username" do
      github_user.fullname = "Robert Reiz"
      github_user.create_username
      github_user.username.should eql("RobertReiz")
    end

    it "does create a username and replace -" do
      github_user.fullname = "Hans -Reiz"
      github_user.create_username
      github_user.username.should eql("HansReiz")
    end

    it "does create a username with a randomValue" do
      github_user.fullname = "Robert Reiz"
      github_user.create_username
      github_user.username.should eql("RobertReiz")
      github_user.save

      user = User.new
      user.fullname = "Robert Reiz"
      user.create_username
      user.username.size.should > 12
    end

  end

  describe "non_followers" do
    it "returns same number of user when users follow nothing" do
      User.non_followers.count.should eql(User.all.count)
    end
    it "returns one user less, when one user starts following new Project" do
      user = User.all.first
      prod = ProductFactory.create_new
      user.products.push prod
      User.non_followers.count.should eql(User.all.count - 1)

      user[:product_ids] = Array.new
      user.save
      User.non_followers.count.should eql(User.all.count)

      user[:product_ids] = nil
      user.save
      User.non_followers.count.should eql(User.all.count)
    end
  end

  describe "follows_least" do
    it "returns nothing, when there's no user with specified number follows" do
      User.follows_least(1).count.should eql(0)
    end

    it "returns only 1 user, who follows least n packages" do
      user = User.all.first
      prod = ProductFactory.create_new
      user.products.push prod
      User.follows_least(1).count.should eql(1)
    end
  end

  describe "follows_max" do
    it "returns all users, when n is large enough" do
      User.follows_max(32768).count.should eql(User.all.count)
    end

    it "returns one user less, when one of un-followers starts following new package" do
      user = User.all.first
      prod = ProductFactory.create_new
      user.products.push prod
      User.follows_max(1).count.should eql(User.all.count - 1)
    end
  end

end
