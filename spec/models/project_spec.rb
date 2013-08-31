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
    @properties = Hash.new
  end

  describe "email_for" do

    it "returns user default email" do
      project = Project.new
      user = User.new
      user.email = "hallo@hallo.de"
      Project.email_for(project, user).should eql("hallo@hallo.de")
    end

    it "returns user default email because the project email does not exist" do
      project = Project.new
      user = User.new
      user.email = "hallo@hallo.de"
      project.email = "hadoop@palm.de"
      Project.email_for(project, user).should eql("hallo@hallo.de")
    end

    it "returns project email" do
      project = Project.new
      user_email = UserEmail.new
      user_email.user_id = @user._id.to_s
      user_email.email = "ping@pong.de"
      user_email.save
      @user.email = "hallo@hallo.de"
      project.email = "ping@pong.de"
      Project.email_for(project, @user).should eql("ping@pong.de")
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
      Project.email_for(project, @user).should eql("hallo@hallo.de")
    end

  end

  describe "make_project_key" do
    before(:each) do
      @test_user = UserFactory.create_new 1001
      @test_user.nil?.should be_false
      @test_project = ProjectFactory.create_new @test_user
    end

    after(:each) do
      @test_user.remove
      @test_project.remove
    end

    it "project factory generated project_key passes validation" do
      @test_project.errors.full_messages.empty?.should be_true
    end

    it "if generates unique project_key if there already exsists similar projects" do
      new_project = ProjectFactory.create_new @test_user
      new_project.valid?.should be_true
      new_project.project_key.should =~ /(\d+)$/
      new_project.remove
    end

    it "if generates unique project_key only once" do
      new_project = ProjectFactory.create_new @test_user
      new_project.valid?.should be_true
      new_project.project_key.should =~ /(\d+)$/
      project_key = new_project.project_key
      new_project.make_project_key!
      new_project.project_key.should eql(project_key)
      new_project.remove
    end
  end

  describe "collaborator" do
    before(:each) do
      @test_user = UserFactory.create_new 10021
      @test_user.nil?.should be_false
      @test_project = ProjectFactory.create_new @test_user
    end

    after(:each) do
      @test_user.remove
      @test_project.remove
    end

    it "project factory generated project_key passes validation" do
      col_user = UserFactory.create_new 10022
      collaborator = ProjectCollaborator.new(:project_id => @test_project._id,
                                             :owner_id => @test_user._id,
                                             :caller_id => @test_user._id )
      collaborator.save
      @test_project.collaborators << collaborator
      @test_project.collaborator(col_user).should be_nil
      collaborator.user_id = col_user._id
      collaborator.save
      collaborator_db = @test_project.collaborator( col_user )
      collaborator_db.should_not be_nil
    end
  end

end
