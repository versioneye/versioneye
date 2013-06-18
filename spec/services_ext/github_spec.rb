require 'spec_helper'

FakeWeb.allow_net_connect = false

FactoryGirl.define do
  factory :user do
    terms true
    datenerhebung true
    salt "sugar"
    password "12345"
    encrypted_password Digest::SHA2.hexdigest("sugar--12345")
  end

  factory :github_repo do
    cached_at 5.minutes.ago
  end
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
    it "should return nil when bad credentials" do
      Github.user("123").should be_nil
    end

    it "should return user data when correct credentials" do
      Github.user("123") #passing the failiing response
      user_data = Github.user("123")

      user_data.should_not be_nil
      user_data.is_a?(Hash).should be_true
      user_data.has_key?("login").should be_true
      user_data['login'].should eql("octocat")
      user_data['company'].should eql('VersionEye')
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

  describe "getting info about user's organization" do
    before :each do
      FakeWeb.register_uri(:get, %r|https://api\.github\.com/orgs/*|,
                          [{body: {message: "Bad credentials"}.to_json},
                           {body: {login: "versioneye",
                                   id: 1,
                                   url: "https://api.github.com/orgs/github",
                                   avatar_url: "https://github.com/images/error/octocat_happy.gif",
                                   name: "versioneye",
                                   company: "VersionEye",
                                   location: "Berlin",
                                   email: "info@versioneye.com",
                                   public_repos: 2,
                                   public_gists: 1,
                                   followers: 20,
                                   following: 0,
                                   html_url: "https://github.com/octocat",
                                   created_at: "2008-01-14T04:33:35Z",
                                   type: "Organization"}.to_json}
                          ])
    end

    it "should return nil when github raises exception" do
      Github.orga_info(user_without_token, "versioneye").should be_nil
    end

    it "returns proper hash with information" do
      Github.orga_info(user_without_token, "versioneye").should be_nil
      
      org_info = Github.orga_info(user_with_token, "versioneye")

      org_info.should_not be_nil
      org_info.is_a?(Hash).should be_true
      org_info.has_key?('login').should be_true
      org_info['login'].should eql('versioneye')
      org_info.has_key?('name').should be_true
      org_info['name'].should eql('versioneye')
      org_info.has_key?('type').should be_true
      org_info['type'].should eql('Organization')
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
      Github.repo_branches(user_without_token, "versioneye/spec").should be_nil
    end

    it "should correct name of branch of given repositories" do
      Github.repo_branches(user_without_token, "versioneye/spec").should be_nil
      
      branches = Github.repo_branches(user_with_token, "versioneye/spec")
      branches.should_not be_nil
      branches.count.should eql(1)
      
      branches.first.has_key?('name').should be_true
      branches.first['name'].should eql('master')
      branches.first['commit']['sha'].should eql("6dcb09b5b57875f334f61aebed695e2e4193db5e")
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
      Github.repo_branch_info(user_without_token, "versioneye/spec", "master").should be_nil
    end

    it "should return proper data when user uses correct info" do
      Github.repo_branch_info(user_without_token, "versioneye/spec", "master").should be_nil
 
      branch_info = Github.repo_branch_info(user_with_token, "versioneye/spec", "master")
      branch_info.should_not be_nil
      branch_info['name'].should eql('master')
    end
  end

  describe "user_repo_names" do
    before :each do
      FakeWeb.clean_registry
      FakeWeb.register_uri(
        :get,
        %r|https://api\.github\.com/user/repos*|,
        [
          {body: {message: "Bad credentials"}.to_json},
          {body: repo_response1},
          {body: repo_response2},
          {body: [].to_json}
        ])
    end

    it "should return empty array when user has wrong token" do
      Github.user_repo_names(user_with_token.github_token).empty?.should be_true
    end

    it "should return array with correct names when asking responses repeatedly" do
      Github.user_repo_names(user_with_token.github_token).empty?.should be_true
      names = Github.user_repo_names(user_with_token.github_token)

      names.should_not be_nil
      names.empty?.should be_false
      names.count.should eql(2)
      names.first.should eql('versioneye/spec1')
      names.second.should eql('versioneye/spec2')
    end
  end

  describe "reading repos names for orga with repo_names_for_orga" do
    before :each do
      FakeWeb.clean_registry
      FakeWeb.register_uri(
        :get,
        %r|https://api\.github\.com/orgs/versioneye/repos*|,
        [
          {body: {message: "Bad credentials"}.to_json},
          {body: repo_response1},
          {body: repo_response2},
          {body: {message: "Should stop now"}.to_json}
        ])
    end

    it "should return empty array when user has wrong token" do
      Github.repo_names_for_orga(user_without_token.github_token, "versioneye").empty?.should be_true
    end

    it "should return array with correct names" do
      Github.repo_names_for_orga(user_without_token.github_token, "versioneye").empty?.should be_true
     
      names = Github.repo_names_for_orga(user_with_token.github_token, "versioneye")
      names.empty?.should be_false
      names.first.should eql('versioneye/spec1')
      names.second.should eql('versioneye/spec2')
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
      Github.orga_names(user_without_token.github_token).empty?.should be_true
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
