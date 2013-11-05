require 'spec_helper'

describe UserService do

  describe "delete" do

    let(:user)   { UserFactory.create_new(34) }

    it "deltes the user in the right way" do
      email = String.new( user.email )
      username = String.new( user.username )
      user.email.should_not be_nil
      user.username.should_not be_nil
      user.fullname.should_not be_nil
      user.github_id = "123"
      user.github_token = "asgasgas"
      user.github_scope = "none"
      user.twitter_id = "456"
      user.twitter_token = "asgfasgfa"
      user.twitter_secret = "asgasgasgas"
      user.save.should be_true
      Notification.count.should eql(0)
      NotificationFactory.create_new user, true
      Notification.count.should eql(1)
      UserService.delete(user).should be_true
      Notification.count.should eql(0)
      user.fullname.should eql("Deleted")
      user.email.should_not eql(email)
      user.username.should_not eql(username)
      user.github_id.should be_nil
      user.github_token.should be_nil
      user.github_scope.should be_nil
      user.twitter_id.should be_nil
      user.twitter_token.should be_nil
      user.twitter_secret.should be_nil
    end

  end

  describe "active_users" do

    before(:each) do
      User.destroy_all
      @user = User.new
      @user.fullname = "Hans Tanz"
      @user.username = "hans_tanz"
      @user.email = "hans@tanz.de"
      @user.password = "password"
      @user.salt = "salt"
      @user.github_id = "github_id_123"
      @user.terms = true
      @user.datenerhebung = true
      @user.save
      UserFactory.create_defaults
    end

    it "returns 3mpty list, when there's no active users" do
      UserService.active_users.count.should eql(0)
    end

    it "returns one user, when there's only one user following" do
      user = User.all.first
      prod = ProductFactory.create_new
      user.products.push prod
      UserService.active_users.count.should eql(1)
    end

    it "returns one user, when there's only one user who have add comment" do
      user = User.all.first
      Versioncomment.new(user_id: user.id, product_key: "1", version: "1", comment: "1").save
      Versioncomment.new(user_id: user.id, product_key: "2", version: "2", comment: "2").save
      UserService.active_users.count.should eql(1)
    end

    it "returns only one user, when there's only one user with active project" do
      user                = User.all.first
      project             = Project.new
      project.user        = user
      project.name        = "test"
      project.project_key = "test"
      project.save
      UserService.active_users.count.should eql(1)
      Project.delete_all
    end

    it "returns only one user, even she commented and has active project" do
      user = User.all.first
      Project.new(user_id: user.id)
      Versioncomment.new(user_id: user.id, product_key: "1", version: "1", comment: "1").save
      UserService.active_users.count.should eql(1)
      Project.delete_all
      Versioncomment.delete_all
    end

    it "returns 2 user,when she commented and he has active project" do
      she                 = User.all.first
      he                  = User.all.last
      project             = Project.new
      project.user        = she
      project.name        = "test"
      project.project_key = "test"
      project.save
      Versioncomment.new(user_id: he.id, product_key: "1", version: "1", comment: "1").save
      UserService.active_users.count.should eql(2)
      Project.delete_all
      Versioncomment.delete_all
    end

  end

end
