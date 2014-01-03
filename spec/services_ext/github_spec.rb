require 'spec_helper'
require 'vcr'
require 'webmock'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes/'
  c.ignore_localhost = true
  c.hook_into :webmock # or :fakeweb
end

describe Github do

  let(:user_without_token) {create(:user, username: "pupujuku",
                                   fullname: "Pupu Juku", email: "juku@pupu.com")}
  let(:user_with_token) {create(:user, username: "aitaleida",
                                fullname: "Leida Aita", email: "leida@aita.com",
                                github_token: "12345")}
  let(:repo1) {create(:github_repo, user_id: user_with_token.id.to_s,
                      github_id: 1, fullname: "spec/repo1",
                      owner_login: "versioneye", owner_type: "user")}
  let(:private_repo_response) {
    {
      id: 1296269,
      owner: {
        login: "versioneye",
        id: 1,
        avatar_url: "https://github.com/images/error/octocat_happy.gif",
        gravatar_id: "somehexcode",
        url: "https://api.github.com/users/octocat"
      },
      name: "private_repo",
      full_name: "versioneye/private_repo",
      description: "This your first private repo!",
      private: true,
      fork: false,
      url: "https://api.github.com/repos/octocat/Hello-World",
      html_url: "https://github.com/octocat/Hello-World",
      clone_url: "https://github.com/octocat/Hello-World.git",
      git_url: "git://github.com/octocat/Hello-World.git",
      ssh_url: "git@github.com:octocat/Hello-World.git",
      svn_url: "https://svn.github.com/octocat/Hello-World",
      mirror_url: "git://git.example.com/octocat/Hello-World",
      homepage: "https://github.com",
      language: "ruby",
      forks: 9,
      forks_count: 9,
      watchers: 80,
      watchers_count: 80,
      size: 108,
      master_branch: "master",
      open_issues: 0,
      pushed_at: "2011-01-26T19:06:43Z",
      created_at: "2011-01-26T19:01:12Z",
      updated_at: "2011-01-26T19:14:43Z"
    }.to_json
  }
  let(:repo_response1) {
      [
        {
          id: 1296269,
          owner: {
            login: "versioneye",
            id: 1,
            avatar_url: "https://github.com/images/error/octocat_happy.gif",
            gravatar_id: "somehexcode",
            url: "https://api.github.com/users/octocat"
          },
          name: "spec1",
          full_name: "versioneye/spec1",
          description: "This your first repo!",
          private: false,
          fork: false,
          url: "https://api.github.com/repos/octocat/Hello-World",
          html_url: "https://github.com/octocat/Hello-World",
          clone_url: "https://github.com/octocat/Hello-World.git",
          git_url: "git://github.com/octocat/Hello-World.git",
          ssh_url: "git@github.com:octocat/Hello-World.git",
          svn_url: "https://svn.github.com/octocat/Hello-World",
          mirror_url: "git://git.example.com/octocat/Hello-World",
          homepage: "https://github.com",
          language: "ruby",
          forks: 9,
          forks_count: 9,
          watchers: 80,
          watchers_count: 80,
          size: 108,
          master_branch: "master",
          open_issues: 0,
          pushed_at: "2011-01-26T19:06:43Z",
          created_at: "2011-01-26T19:01:12Z",
          updated_at: "2011-01-26T19:14:43Z"
        }
      ].to_json
  }

  let(:repo_response2) {
    [
      {
        id: 1296269,
        owner: {
          login: "versioneye",
          id: 1,
          avatar_url: "https://github.com/images/error/octocat_happy.gif",
          gravatar_id: "somehexcode",
          url: "https://api.github.com/users/octocat"
        },
        name: "spec2",
        full_name: "versioneye/spec2",
        description: "This your second repo!",
        private: false,
        fork: false,
        url: "https://api.github.com/repos/octocat/Hello-World",
        html_url: "https://github.com/octocat/Hello-World",
        clone_url: "https://github.com/octocat/Hello-World.git",
        git_url: "git://github.com/octocat/Hello-World.git",
        ssh_url: "git@github.com:octocat/Hello-World.git",
        svn_url: "https://svn.github.com/octocat/Hello-World",
        mirror_url: "git://git.example.com/octocat/Hello-World",
        homepage: "https://github.com",
        language: "ruby",
        forks: 9,
        forks_count: 9,
        watchers: 80,
        watchers_count: 80,
        size: 108,
        master_branch: "master",
        open_issues: 0,
        pushed_at: "2011-01-26T19:06:43Z",
        created_at: "2011-01-26T19:01:12Z",
        updated_at: "2011-01-26T19:14:43Z"
      }
    ].to_json
  }


  describe "getting user information via API" do
    before :each do
      FakeWeb.allow_net_connect = false

      FakeWeb.register_uri(:get, %r|https://api\.github\.com/user*|,
                           [{:body => {"message"=>"Bad credentials"}.to_json},
                            {:body => {
                              login: "octocat",
                              id: 1,
                              avatar_url: "https://github.com/images/error/octocat_happy.gif",
                              gravatar_id: "somehexcode",
                              name: "monalisa octocat",
                              company: "VersionEye"}.to_json}]
)
    end

    after :each do
      FakeWeb.clean_registry
      FakeWeb.allow_net_connect = true
    end

    it "should return nil when user has no credentials" do
      response = Github.user(nil)
      response.should be_nil
    end

    it "should return nil when bad credentials" do
      response = Github.user("smt-very-wrong")
      response.should be_nil
    end

    it "should return user data when correct credentials" do
      VCR.use_cassette('github_signup', :allow_playback_repeats => true) do
        user_data = Github.user("3974100548430f742b9716b2e26ba73437fe8028")
        user_data.should_not be_nil
        user_data.is_a?(Hash).should be_true
        user_data.has_key?("login").should be_true
        user_data['login'].should eql("reiz")
        user_data['company'].should eql('VersionEye')
      end
    end
  end

  describe "checkin changes of user's repositories" do
    before :each do
      FakeWeb.register_uri(:head, %|https://api\.github\.com/user|,
                          [{status: ["403" "Forbidden"], body: {message: "Bad credentials"}.to_json},
                           {status: ["200", "OK"], body: "OK"},
                           {status: ["304", "Not Modified"], body: "Not modified"}])
      it "should return true when cache is empty" do
        Github.user_repo_changed?(user_with_token).should be_true
      end

      it "should return true, even when github raise exception" do
        Github.user_repo_changed?(user_without_token).should be_true
      end

      it "should return true, when there has been changes on user account" do
        Github.user_repo_changed?(user_with_token) #pass the first response
        Github.user_repo_changed?(user_with_token).should be_true
      end

      it "should false, when there's no changes on user account" do
        Github.user_repo_changed?(user_with_token) #pass the first response
        Github.user_repo_changed?(user_with_token) #pass the second response
        Github.user_repo_changed?(user_with_token).should be_true
      end
    end
  end

  describe "reading repositories by following links in response headers" do
    let(:url_start) {"https://api.github.com/user/repos"}
    let(:url_page2) {"https://api.github.com/user/repos?page=2"}
    before :each do
      FakeWeb.clean_registry
      FakeWeb.register_uri(:get, %r|https://api\.github\.com/user/repos*|,
                           [
                            {body: {message: "Bad credentials"}.to_json},
                            {"Link" => "<#{url_page2}>; rel=\"next\", <#{url_page2}>; rel=\"last\"",
                              body: [].to_json}
                           ])
      FakeWeb.register_uri(:get, %r|https://api\.github\.com/repos/*/branches*|, {body: [].to_json})
    end

    it "should response hash-map where 'repos' are empty array when user has wrong credentials" do
      response = Github.read_repos(user_without_token, url_start)
      response.should_not be_nil
      response.has_key?(:repos).should be_true
      response[:repos].empty?.should be_true
    end

    it "should parse correctly url from response header" do
       response = Github.read_repos(user_without_token, url_start)
       # TODO TG condition is here missing on response.

       response = Github.read_repos(user_with_token, url_start)
       response.should_not be_nil
       response.has_key?(:paging).should be_true
       response[:paging].has_key?("next").should be_true
       response[:paging]["next"].should eql(url_page2)
    end
  end

  describe "reading branches for specific repository" do
    before :each do
      FakeWeb.clean_registry
      FakeWeb.register_uri(
        :get,
        %r|https://api\.github\.com/repos/versioneye/spec/branches*|,
        [
          {body: {message: "Bad credentials"}.to_json},
          {body: [{name: "master",
                   commit: {sha: "6dcb09b5b57875f334f61aebed695e2e4193db5e",
                            url: "https://api.github.com/repos/octocat/Hello-World/commits/\
                            c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc"
                            }
                  }].to_json
          }
        ])
    end

    it "should nil when user is having wrong credentials" do
      Github.repo_branches("versioneye/spec", user_without_token[:github_token]).should be_nil
    end

    it "should correct name of branch of given repositories" do
      Github.repo_branches("versioneye/spec", user_without_token[:github_token]).should be_nil

      branches = Github.repo_branches("versioneye/spec", user_with_token[:github_token])
      branches.should_not be_nil
      branches.count.should eql(1)

      branches.first.has_key?(:name).should be_true
      branches.first[:name].should eql('master')
      branches.first[:commit][:sha].should eql("6dcb09b5b57875f334f61aebed695e2e4193db5e")
    end
  end

  describe "reading information for specific branch of the repository" do
    before :each do
      FakeWeb.clean_registry
      FakeWeb.register_uri(
        :get,
        %r|https://api\.github\.com/repos/versioneye/spec/branches/*|,
        [{body: {message: "Bad credentials"}.to_json},
         {body: {name: "master",
                 commit: {sha: "7fd1a60b01f91b314f59955a4e4d4e80d8edf11d"}}.to_json
         }]
      )
    end

    it "should return nil when user uses wrong credentials" do
      token = user_without_token[:github_token]
      Github.repo_branch_info("versioneye/spec", "master", token).should be_nil
    end

    it "should return proper data when user uses correct info" do
      token = user_without_token[:github_token]
      Github.repo_branch_info("versioneye/spec", "master", token).should be_nil

      token = user_with_token[:github_token]
      branch_info = Github.repo_branch_info("versioneye/spec", "master", token)
      branch_info.should_not be_nil
      branch_info[:name].should eql('master')
    end
  end

  describe "reading names of user's organizations with orga_names" do
    before :each do
      FakeWeb.clean_registry
      FakeWeb.register_uri(
        :get,
        %r|https://api\.github\.com/user/orgs*|,
        [
          {body: {message: "Bad credentials"}.to_json},
          {body: [
                  {
                    login: "versioneye",
                    id: 1,
                    url: "https://api.github.com/orgs/github",
                    avatar_url: "https://github.com/images/error/octocat_happy.gif"
                  }
                 ].to_json
          }
        ]
      )
    end

    it "should return empty array when github returns exception"  do
      Github.orga_names(user_without_token[:github_token]).empty?.should be_true
    end

    it "should return list with right names" do
      Github.orga_names(user_without_token.github_token).empty?.should be_true

      names = Github.orga_names(user_with_token.github_token)
      names.empty?.should be_false
      names.first.should eql('versioneye')
    end
  end

  describe "getting visibility of user's github repo with private_repo?" do
    before :each do
      FakeWeb.register_uri(
        :get,
        %r|https://api\.github\.com/repos/versioneye*|,
        [
          {body: {message: "Bad credentials"}.to_json},
          {body: private_repo_response}
        ]
      )
    end

    it "should return false when github raises exception" do
      Github.private_repo?(user_without_token.github_token, "versioneye").should be_false
    end

    it "should be true when everything goes as planned and fakeweb returns correct response" do
      Github.private_repo?(user_without_token.github_token, "versioneye").should be_false
      Github.private_repo?(user_without_token.github_token, "versioneye").should be_true
    end
  end
end
