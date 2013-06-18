require 'spec_helper'


FactoryGirl.define do
  factory :user do
    terms true
    datenerhebung true
    salt "sugar"
    password "12345"
    github_token "random-token-bla-bla"
    encrypted_password Digest::SHA2.hexdigest("sugar--12345") 
  end

  factory :github_repo do
    cached_at 5.minutes.ago
  end

  factory :dependency do
    name "spec_prod2"
    version "0.1.1"
    dep_prod_key "spec_dep1_key"
    prod_key ""
    prod_version "0.1"
    known true
  end

  sequence :product_name do |n|
    "spec_product#{n}"
  end

  factory :product do
    name "spec_main_product"
    prod_key "spec_product_key"
    language "ruby"
    version "0.1"

    factory :product_with_deps do
      ignore do
        deps_count 0
      end

      after(:create) do |product, evaluator|
        prod_name = FactoryGirl.generate(:product_name)
        FactoryGirl.create_list(:dependency, evaluator.deps_count, name: prod_name, 
                                prod_key: product._id.to_s, prod_version: product.version)
      end
    end
  end

  factory :projectdependency do
    prod_key ""
    name ""
    version_current "0.1"
    version_requested "0.1"
    comperator "="
    outdated false
  end

  factory :project do
    name "spec_project_1"
    project_type "RubyGem"
    language "Ruby"
    
    factory :project_with_deps do
      ignore do 
        deps_count 0
      end

      after(:build) do |project, evaluator|
        prod_name = FactoryGirl.generate(:product_name)
        deps = FactoryGirl.create_list(:projectdependency, evaluator.deps_count, 
                                       name: prod_name)
        project.projectdependencies = deps
        project.make_project_key!
      end
    end
  end
end

describe "Importing github repo as new project via github_repos_controller" do
  describe "when user is unauthorized" do
    it "redirects to signin page" do
      post user_github_repos_path
      response.status.should eql(302)
   end
  end

  describe "when user is propely authorized" do
    let(:user) {create(:user, username: "pupujuku", fullname: "Pupu Juku", email: "juku@pupu.com")}

    let(:repo1) {build(:github_repo, user_id: user.id.to_s, github_id: 1, 
                       fullname: "spec/repo1", user_login: "a", 
                       owner_login: "versioneye", owner_type: "user")}
    let(:repo2) {build(:github_repo, user_id: user.id.to_s, github_id: 2, 
                       fullname: "spec/repo2", user_login: "a", 
                       owner_login: "versioneye", owner_type: "user")}
    let(:project1) {build(:project_with_deps, deps_count: 3, 
                          name: "spec_projectX", user_id: user.id.to_s)}

    before :each do
      GithubRepo.delete_all

      get signin_path, nil, "HTTPS" => "on"
      post sessions_path, {session: {email: user.email, password: "12345"}}, "HTTPS" => "on"
      assert_response 302
      response.should redirect_to(new_user_project_path)

      repo1.save
      repo2.save
    end

    it "should raise exception when request misses  required fields" do
      post user_github_repos_path
      response.status.should eql(400)
    end

    it "should raise exception when user tries to import not existing repo" do
      ProjectService.should_receive(:import_from_github).and_return(nil) 
      repo1['command'] = "import"

      post user_github_repos_path, repo1.as_document
      response.status.should eql(503)
    end

    it "should return updated repo model when importing succeeds" do
      project1.save.should be_true

      project1.projectdependencies.size.should > 0
      ProjectService.should_receive(:import_from_github).and_return(project1) 
      repo1['command'] = "import"

      post user_github_repos_path, repo1.as_document
      response.status.should eql(200)
    end

    it "should remove project after imported project succeeds" do
      project1.save.should be_true

      ProjectService.should_receive(:destroy_project).and_return(true)
      repo1['command'] = 'remove'
      repo1['project_id'] = project1._id.to_s
      post user_github_repos_path, repo1.as_document

      response.status.should eql(200)
    end
  end
end
