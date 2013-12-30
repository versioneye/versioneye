require 'spec_helper'

describe Project do

  before(:each) do
    @user = User.new
    @user.fullname = "Hans Tanz"
    @user.username = "hanstanz"
    @user.email = "hans@tanz.de"
    @user.password = "password"
    @user.salt = "salt"
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

    it "project factory generated project_key passes validation" do
      col_user     = UserFactory.create_new 10022
      collaborator = ProjectCollaborator.new(:project_id => @test_project._id,
                                             :owner_id => @test_user._id,
                                             :caller_id => @test_user._id )
      collaborator.save
      @test_project.collaborators << collaborator
      @test_project.collaborator( col_user ).should be_nil
      @test_project.collaborator( @test_user ).should be_nil
      @test_project.collaborator( nil ).should be_nil

      @test_project.collaborator?( col_user ).should be_false
      @test_project.collaborator?( nil ).should be_false
      @test_project.collaborator?( @test_user ).should be_true

      collaborator.user_id = col_user._id
      collaborator.save
      collaborator_db = @test_project.collaborator( col_user )
      collaborator_db.should_not be_nil
      collaborator_db.user.username.should eql( col_user.username )
      @test_project.collaborator?( col_user ).should be_true

      @test_project.remove_collaborators
      @test_project.collaborators.size.should eq(0)
      @test_project.collaborators.count.should eq(0)
      @test_project.collaborator( col_user ).should be_nil
    end
  end

  describe "visible_for_user?" do
    before(:each) do
      @test_user = UserFactory.create_new 1023
      @test_user.nil?.should be_false
      @test_project = ProjectFactory.create_new @test_user
      @test_project.public = false
      @test_project.save
    end

    after(:each) do
      @test_user.remove
      @test_project.remove
    end

    it "project factory generated project_key passes validation" do
      col_user = UserFactory.create_new 1024
      collaborator = ProjectCollaborator.new(:project_id => @test_project._id,
                                             :owner_id => @test_user._id,
                                             :caller_id => @test_user._id )
      collaborator.save
      @test_project.collaborators << collaborator
      @test_project.visible_for_user?( col_user ).should be_false
      @test_project.visible_for_user?( nil ).should be_false
      @test_project.visible_for_user?( @test_user ).should be_true
      @test_project.public = true
      @test_project.save
      @test_project.visible_for_user?( col_user ).should be_true
      @test_project.public = false
      @test_project.save
      @test_project.visible_for_user?( col_user ).should be_false
      @test_project.visible_for_user?( @test_user ).should be_true
      collaborator.user_id = col_user._id
      collaborator.save
      @test_project.visible_for_user?( col_user ).should be_true
      @test_project.visible_for_user?( @test_user ).should be_true
    end
  end

  describe "unmuted_dependencies" do
    it "returns muted and unmuted dependencies" do
      user = UserFactory.create_new 1066
      user.nil?.should be_false
      project = ProjectFactory.create_new user
      project.public = false
      project.save

      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      product_3 = ProductFactory.create_new 3

      ProjectdependencyFactory.create_new project, product_1
      ProjectdependencyFactory.create_new project, product_2
      dep_3 = ProjectdependencyFactory.create_new project, product_3

      unmuted = project.unmuted_dependencies
      unmuted.should_not be_nil
      unmuted.count.should eq(3)
      project.muted_prod_keys.should be_empty

      dep_3.muted = true
      dep_3.save

      unmuted = project.unmuted_dependencies
      unmuted.should_not be_nil
      unmuted.count.should eq(2)

      prod_keys = project.muted_prod_keys
      prod_keys.should_not be_empty
      prod_keys.count.should eq(1)
      prod_keys.first.should eql("#{dep_3.language}_#{dep_3.prod_key}_#{dep_3.version_current}")

      muted = project.muted_dependencies
      muted.should_not be_nil
      muted.count.should eq(1)
      muted.first._id.should eql(dep_3._id)

      user.remove
      project.remove
    end
  end

  describe "overwrite_dependencies" do
    it "overwrites dependencies" do
      user = UserFactory.create_new 1066
      user.nil?.should be_false
      project = ProjectFactory.create_new user
      project.save

      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      product_3 = ProductFactory.create_new 3

      dep_1 = ProjectdependencyFactory.create_new project, product_1
      dep_1.version_current = "2.0.0"
      dep_1.version_requested = "1.0.0"
      dep_1.save
      dep_2 = ProjectdependencyFactory.create_new project, product_2
      dep_2.version_current = "2.0.0"
      dep_2.version_requested = "1.0.0"
      dep_2.muted = true
      dep_2.save
      dep_3 = ProjectdependencyFactory.create_new project, product_3
      dep_3.version_current = "2.0.0"
      dep_3.version_requested = "1.0.0"
      dep_3.muted = true
      dep_3.save

      unmuted = project.unmuted_dependencies
      unmuted.count.should eq(1)

      dep_4 = Projectdependency.new
      dep_4.language = dep_1.language
      dep_4.prod_key = dep_1.prod_key
      dep_4.version_current = "2.0.0"
      dep_4.version_requested = "1.0.0"
      dep_4.save
      dep_5 = Projectdependency.new
      dep_5.language = dep_2.language
      dep_5.prod_key = dep_2.prod_key
      dep_5.version_current = "2.1.0"   # Current version goes 1 up. That will reset the muted to false!
      dep_5.version_requested = "1.0.0"
      dep_5.save
      dep_6 = Projectdependency.new
      dep_6.language = dep_3.language
      dep_6.prod_key = dep_3.prod_key
      dep_6.version_current = "2.0.0"
      dep_6.version_requested = "1.0.0"
      dep_6.save
      new_deps = Array.new
      new_deps.push dep_4
      new_deps.push dep_5
      new_deps.push dep_6

      project.overwrite_dependencies( new_deps )

      unmuted = project.unmuted_dependencies
      unmuted.count.should eq(2)

      muted = project.muted_dependencies
      muted.count.should eq(1)
      muted.first.prod_key.should eql( dep_6.prod_key )
    end
  end

end
