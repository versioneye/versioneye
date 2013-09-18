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

end
