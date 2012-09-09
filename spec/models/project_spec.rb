require 'spec_helper'

describe Project do

  before(:each) do
    @user = User.new
    @user.fullname = "Hans Tanz"
    @user.username = "hanstanz"
    @user.email = "hans@tanz.de"
    @user.password = "password"
    @user.salt = "salt"
    @user.fb_id = "asggffffffff"
    @user.terms = true
    @user.datenerhebung = true
    @user.save
  end
  
  after(:each) do 
    @user.remove
  end
  
  before(:each) do
    @properties = Hash.new
  end

  describe "get_email_for" do 
    
    it "returns user default email" do 
      project = Project.new 
      user = User.new 
      user.email = "hallo@hallo.de"
      Project.get_email_for(project, user).should eql("hallo@hallo.de")
    end

    it "returns user default email because the project email does not exist" do 
      project = Project.new 
      user = User.new 
      user.email = "hallo@hallo.de"
      project.email = "hadoop@palm.de"
      Project.get_email_for(project, user).should eql("hallo@hallo.de")
    end

    it "returns project email" do 
      project = Project.new 
      user_email = UserEmail.new 
      user_email.user_id = @user._id.to_s
      user_email.email = "ping@pong.de"
      user_email.save
      @user.email = "hallo@hallo.de"
      project.email = "ping@pong.de"
      Project.get_email_for(project, @user).should eql("ping@pong.de")
    end

    it "returns user email because project email is not verified" do 
      project = Project.new 
      user_email = UserEmail.new 
      user_email.user_id = @user._id.to_s
      user_email.email = "ping@pong.de"
      user_email.verification = "verify_me"
      user_email.save
      @user.email = "hallo@hallo.de"
      project.email = "ping@pong.de"
      Project.get_email_for(project, @user).should eql("hallo@hallo.de")
    end

  end
  
end