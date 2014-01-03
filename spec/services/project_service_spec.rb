require 'spec_helper'

describe ProjectService do

  let(:github_user) { FactoryGirl.create(:github_user)}

  describe "type_by_filename" do
    it "returns RubyGems. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_Gemfile?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      url2 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_Gemfile.lock?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_RUBYGEMS)
      described_class.type_by_filename(url2).should eql(Project::A_TYPE_RUBYGEMS)
      described_class.type_by_filename("Gemfile").should eql(Project::A_TYPE_RUBYGEMS)
      described_class.type_by_filename("Gemfile.lock").should eql(Project::A_TYPE_RUBYGEMS)
      described_class.type_by_filename("app/Gemfile").should eql(Project::A_TYPE_RUBYGEMS)
      described_class.type_by_filename("app/Gemfile.lock").should eql(Project::A_TYPE_RUBYGEMS)
    end
    it "returns nil for wrong Gemfiles. OK" do
      described_class.type_by_filename("Gemfile/").should be_nil
      described_class.type_by_filename("Gemfile.lock/a").should be_nil
      described_class.type_by_filename("app/Gemfile/new.html").should be_nil
      described_class.type_by_filename("app/Gemfile.lock/new").should be_nil
    end

    it "returns Composer. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_composer.json?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_COMPOSER)
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_COMPOSER)
      described_class.type_by_filename("composer.json").should eql(Project::A_TYPE_COMPOSER)
      described_class.type_by_filename("composer.lock").should eql(Project::A_TYPE_COMPOSER)
      described_class.type_by_filename("app/composer.json").should eql(Project::A_TYPE_COMPOSER)
      described_class.type_by_filename("app/composer.lock").should eql(Project::A_TYPE_COMPOSER)
    end
    it "returns nil for wrong composer. OK" do
      described_class.type_by_filename("composer.json/").should be_nil
      described_class.type_by_filename("composer.lock/a").should be_nil
      described_class.type_by_filename("app/composer.json/new.html").should be_nil
      described_class.type_by_filename("app/composer.lock/new").should be_nil
    end

    it "returns PIP. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_requirements.txt?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_PIP)
      described_class.type_by_filename("requirements.txt").should eql(Project::A_TYPE_PIP)
      described_class.type_by_filename("app/requirements.txt").should eql(Project::A_TYPE_PIP)
    end
    it "returns nil for wrong pip file" do
      described_class.type_by_filename("requirements.txta").should be_nil
      described_class.type_by_filename("app/requirements.txt/new").should be_nil
    end

    it "returns NPM. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_package.json?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_NPM)
      described_class.type_by_filename("package.json").should eql(Project::A_TYPE_NPM)
      described_class.type_by_filename("app/package.json").should eql(Project::A_TYPE_NPM)
    end
    it "returns nil for wrong npm file" do
      described_class.type_by_filename("package.jsona").should be_nil
      described_class.type_by_filename("app/package.json/new").should be_nil
    end

    it "returns Gradle. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_dep.gradle?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_GRADLE)
      described_class.type_by_filename("dependencies.gradle").should eql(Project::A_TYPE_GRADLE)
      described_class.type_by_filename("app/dependencies.gradle").should eql(Project::A_TYPE_GRADLE)
      described_class.type_by_filename("app/deps.gradle").should eql(Project::A_TYPE_GRADLE)
    end
    it "returns nil for wrong gradle file" do
      described_class.type_by_filename("dependencies.gradlea").should be_nil
      described_class.type_by_filename("dep.gradleo1").should be_nil
      described_class.type_by_filename("app/dependencies.gradle/new").should be_nil
      described_class.type_by_filename("app/dep.gradle/new").should be_nil
    end

    it "returns Maven2. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_pom.xml?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should          eql(Project::A_TYPE_MAVEN2)
      described_class.type_by_filename("app/pom.xml").should eql(Project::A_TYPE_MAVEN2)
    end
    it "returns nil for wrong maven2 file" do
      described_class.type_by_filename("pom.xmla").should be_nil
      described_class.type_by_filename("app/pom.xml/new").should be_nil
    end

    it "returns Lein. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_project.clj?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_LEIN)
      described_class.type_by_filename("project.clj").should eql(Project::A_TYPE_LEIN)
      described_class.type_by_filename("app/project.clj").should eql(Project::A_TYPE_LEIN)
    end
    it "returns nil for wrong Lein file" do
      described_class.type_by_filename("project.clja").should be_nil
      described_class.type_by_filename("app/project.clj/new").should be_nil
    end

  end


  describe "allowed_to_add_project?" do

    it "allows because its a public project" do
      described_class.allowed_to_add_project?(nil, false).should be_true
    end

    it "denies because user doesn't have a private plan" do
      described_class.allowed_to_add_project?(github_user, true).should be_false
    end

    it "allows because user has a plan and no projects" do
      Plan.create_default_plans
      plan = Plan.by_name_id( Plan::A_PLAN_PERSONAL )
      user = github_user
      user.plan = plan
      user.save
      described_class.allowed_to_add_project?(github_user, true).should be_true
    end

    it "denies because user has a plan and to many private projects already" do
      Plan.create_default_plans
      plan = Plan.by_name_id( Plan::A_PLAN_PERSONAL )
      user = github_user
      user.plan = plan
      user.save
      plan.private_projects.times { ProjectFactory.create_new( user, {:private_project => true} ) }
      described_class.allowed_to_add_project?(github_user, true).should be_false
    end

    it "allows because user has a plan and to many private projects already, but 1 additional free project" do
      Plan.create_default_plans
      plan = Plan.by_name_id( Plan::A_PLAN_PERSONAL )
      user = github_user
      user.plan = plan
      user.free_private_projects = 1
      user.save
      plan.private_projects.times { ProjectFactory.create_new( user, {:private_project => true} ) }
      described_class.allowed_to_add_project?(github_user, true).should be_true
    end

    it "denises because user has a plan and to many private projects already" do
      Plan.create_default_plans
      plan = Plan.by_name_id( Plan::A_PLAN_PERSONAL )
      user = github_user
      user.plan = plan
      user.free_private_projects = 1
      user.save
      max = plan.private_projects + user.free_private_projects
      max.times { ProjectFactory.create_new( user, {:private_project => true} ) }
      described_class.allowed_to_add_project?(github_user, true).should be_false
    end

  end


end
