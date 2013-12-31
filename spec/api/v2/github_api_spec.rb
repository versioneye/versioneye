require 'spec_helper'
require 'vcr'
require 'webmock'

describe "GithubApiV2" do

  let(:user) {create(:user, username: "pupujuku", fullname: "Pupu Juku", email: "juku@pupu.com", terms: true, datenerhebung: true)}
  let(:user2) {create(:user, username: "dontshow", fullname: "Don TShow", email: "dont@show.com", terms: true, datenerhebung: true)}

  let(:user_api) { ApiFactory.create_new(user) }

  let(:repo1) {create(:github_repo, user_id: user.id.to_s, github_id: 1,
                      fullname: "spec/repo1", user_login: "a",
                      owner_login: "versioneye", owner_type: "user")}
  let(:repo2) {create(:github_repo, user_id: user.id.to_s, github_id: 2,
                      fullname: "spec/repo2", user_login: "a",
                      owner_login: "versioneye", owner_type: "user")}
  let(:repo3) {create(:github_repo, user_id: user2.id.to_s, github_id: 3,
                    fullname: "spec/repo2", user_login: "b",
                    owner_login: "dont", owner_type: "user")}
  let(:repo_key1) {Product.encode_prod_key(repo1[:fullname])}
  let(:project1) {create(:project_with_deps,
                         deps_count: 3,
                         name: "spec_projectX",
                         user_id: user.id.to_s,
                         source: Project::A_SOURCE_GITHUB,
                         scm_fullname: repo1[:fullname],
                         scm_branch: "master"
                  )}
  let(:api_path) {"/api/v2/github"}


  describe "when user is unauthorized" do

    before :each do
      FakeWeb.allow_net_connect = true
      WebMock.allow_net_connect!
    end

    it "raises http error when asking list of repos" do
      get api_path,  nil, "HTTPS" => "on"
      response.status.should eql(401)
    end

    it "raises http error when asking info of repo" do
      get "#{api_path}/#{repo_key1}", nil, "HTTPS" => "on"
      response.status.should eql(401)
    end

    it "raises http error when trying to post new repo" do
      post "#{api_path}/#{repo_key1}", nil, "HTTPS" => "on"
      response.status.should eql(401)
    end
    it "raises http error when unauthorized user wants remove project" do
      delete "#{api_path}/#{repo_key1}", nil, "HTTPS" => "on"
      response.status.should eql(401)
    end
  end

  describe "when user is properly authorized" do
    before :each do
      FakeWeb.allow_net_connect = false
      FakeWeb.register_uri(:head, %r|https://api\.github\.com/user*|,
                           {status: ["304", "Not Modified"], body: "Not modified"})
      FakeWeb.register_uri(:get, %r|https://api\.github\.com/user*|, {body: "{}"})
      FakeWeb.register_uri(:get, %r|https://api\.github\.com/repos/spec/repo1/branches*|,
                           {body: %Q|
                              {
                                "name": "master",
                                "commit": {
                                  "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
                                  "url": "https://api.github.com/repos/octocat/Hello-World/commits/c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc"
                                }
                              }
                            |
                          })
      FakeWeb.register_uri(:get, %r|https://api.github.com/repos/spec/repo1/git/trees|,
                           {body: %Q|
                            {
                            "sha": "9fb037999f264ba9a7fc6274d15fa3ae2ab98312",
                            "url": "https://api.github.com/repos/octocat/Hello-World/trees/9fb037999f264ba9a7fc6274d15fa3ae2ab98312",
                            "tree": [{
                                      "path": "Gemfile",
                                      "mode": "100644",
                                      "type": "blob",
                                      "size": 30,
                                      "sha": "44b4fc6d56897b048c772eb4087f854f46256132",
                                      "url": "https://api.github.com/repos/octocat/Hello-World/git/blobs/44b4fc6d56897b048c772eb4087f854f46256132"
                                      }]
                            }
                            |
                          })
      repo1.save
      repo2.save
      project1.save
    end

    after :each do
      FakeWeb.clean_registry
      FakeWeb.allow_net_connect = true
    end

    it "should show all user repos" do
      get api_path, {:api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eql(200)

      repos = JSON.parse response.body
      repos.should_not be_nil
      repos.empty?.should_not be_true
      repos.count.should eql(2)
    end

    it "should raise error when user tries to access repository which doest exists" do
      get "#{api_path}/pedestal:pedestal", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eql(400)
    end

    it "should show repo info" do
      get "#{api_path}/#{repo_key1}", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eql(200)

      repo = JSON.parse response.body
      repo.should_not be_nil
      repo.has_key?('repo').should be_true
      repo['repo']['fullname'].should eql("spec/repo1")
    end

    it "should raise error when user tries to import repository which doesnt exists" do
      post "#{api_path}/pedestal:pedestal", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eql(400)
    end

    it "should create new object with repo key" do
      post "#{api_path}/#{repo_key1}", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eql(201)

      repo = JSON.parse response.body
      repo.should_not be_nil
      repo.has_key?('repo').should be_true
      repo['repo']['fullname'].should eql("spec/repo1")
      repo.has_key?('imported_projects').should be_true

      project = repo['imported_projects'].first
      project["name"].should eql("spec_projectX")
    end

    it "should raise error when user tries to remove repository which doesnt exists" do
      delete "#{api_path}/pedestal:pedestal", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eql(400)
    end
    it "should remove project with repo key" do
      delete "#{api_path}/#{repo_key1}", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eql(200)
      msg = JSON.parse response.body
      msg.should_not be_nil
      msg.empty?.should be_false
      msg.has_key?('success').should be_true
      msg['success'].should be_true
    end
  end

  describe "github_hook" do

    it "should return 200" do
      post "#{api_path}/#{repo_key1}", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eql(201)
    end

  end

end
