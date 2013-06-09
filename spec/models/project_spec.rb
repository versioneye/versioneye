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

  after(:each) do
    @user.remove
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

  describe "type_by_filename" do
    it "returns RubyGems. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_Gemfile?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      url2 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_Gemfile.lock?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      Project.type_by_filename(url1).should eql(Project::A_TYPE_RUBYGEMS)
      Project.type_by_filename(url2).should eql(Project::A_TYPE_RUBYGEMS)
      Project.type_by_filename("Gemfile").should eql(Project::A_TYPE_RUBYGEMS)
      Project.type_by_filename("Gemfile.lock").should eql(Project::A_TYPE_RUBYGEMS)
      Project.type_by_filename("app/Gemfile").should eql(Project::A_TYPE_RUBYGEMS)
      Project.type_by_filename("app/Gemfile.lock").should eql(Project::A_TYPE_RUBYGEMS)
    end
    it "returns nil for wrong Gemfiles. OK" do
      Project.type_by_filename("Gemfile/").should be_nil
      Project.type_by_filename("Gemfile.lock/a").should be_nil
      Project.type_by_filename("app/Gemfile/new.html").should be_nil
      Project.type_by_filename("app/Gemfile.lock/new").should be_nil
    end

    it "returns Composer. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_composer.json?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      url2 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_composer.lock?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      Project.type_by_filename(url1).should eql(Project::A_TYPE_COMPOSER)
      Project.type_by_filename(url1).should eql(Project::A_TYPE_COMPOSER)
      Project.type_by_filename("composer.json").should eql(Project::A_TYPE_COMPOSER)
      Project.type_by_filename("composer.lock").should eql(Project::A_TYPE_COMPOSER)
      Project.type_by_filename("app/composer.json").should eql(Project::A_TYPE_COMPOSER)
      Project.type_by_filename("app/composer.lock").should eql(Project::A_TYPE_COMPOSER)
    end
    it "returns nil for wrong composer. OK" do
      Project.type_by_filename("composer.json/").should be_nil
      Project.type_by_filename("composer.lock/a").should be_nil
      Project.type_by_filename("app/composer.json/new.html").should be_nil
      Project.type_by_filename("app/composer.lock/new").should be_nil
    end

    it "returns PIP. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_requirements.txt?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      Project.type_by_filename(url1).should eql(Project::A_TYPE_PIP)
      Project.type_by_filename("requirements.txt").should eql(Project::A_TYPE_PIP)
      Project.type_by_filename("app/requirements.txt").should eql(Project::A_TYPE_PIP)
    end
    it "returns nil for wrong pip file" do
      Project.type_by_filename("requirements.txta").should be_nil
      Project.type_by_filename("app/requirements.txt/new").should be_nil
    end

    it "returns NPM. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_package.json?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      Project.type_by_filename(url1).should eql(Project::A_TYPE_NPM)
      Project.type_by_filename("package.json").should eql(Project::A_TYPE_NPM)
      Project.type_by_filename("app/package.json").should eql(Project::A_TYPE_NPM)
    end
    it "returns nil for wrong npm file" do
      Project.type_by_filename("package.jsona").should be_nil
      Project.type_by_filename("app/package.json/new").should be_nil
    end

    it "returns Gradle. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_dep.gradle?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      Project.type_by_filename(url1).should eql(Project::A_TYPE_GRADLE)
      Project.type_by_filename("dependencies.gradle").should eql(Project::A_TYPE_GRADLE)
      Project.type_by_filename("app/dependencies.gradle").should eql(Project::A_TYPE_GRADLE)
      Project.type_by_filename("app/deps.gradle").should eql(Project::A_TYPE_GRADLE)
    end
    it "returns nil for wrong gradle file" do
      Project.type_by_filename("dependencies.gradlea").should be_nil
      Project.type_by_filename("dep.gradleo1").should be_nil
      Project.type_by_filename("app/dependencies.gradle/new").should be_nil
      Project.type_by_filename("app/dep.gradle/new").should be_nil
    end

    it "returns Maven2. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_pom.xml?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      Project.type_by_filename(url1).should eql(Project::A_TYPE_MAVEN2)
      Project.type_by_filename("app/pom.xml").should eql(Project::A_TYPE_MAVEN2)
    end
    it "returns nil for wrong maven2 file" do
      Project.type_by_filename("pom.xmla").should be_nil
      Project.type_by_filename("app/pom.xml/new").should be_nil
    end

    it "returns Lein. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_project.clj?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      Project.type_by_filename(url1).should eql(Project::A_TYPE_LEIN)
      Project.type_by_filename("project.clj").should eql(Project::A_TYPE_LEIN)
      Project.type_by_filename("app/project.clj").should eql(Project::A_TYPE_LEIN)
    end
    it "returns nil for wrong Lein file" do
      Project.type_by_filename("project.clja").should be_nil
      Project.type_by_filename("app/project.clj/new").should be_nil
    end

  end

end
