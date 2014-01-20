require 'spec_helper'

describe "Importing github repo as new project via github_repos_controller" do
  describe "when user is unauthorized" do
    it "redirects to signin page" do
      get user_github_repos_path
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
      response.should redirect_to( user_packages_i_follow_path )

      repo1.save
      repo2.save
    end

    it "should raise exception when request misses  required fields" do
      put "#{user_github_repos_path}/#{repo1[:_id]}"
      response.status.should eql(400)
    end

    it "should raise exception when user tries to import not existing repo" do
      ProjectService.should_receive(:import_from_github).and_return nil
      repo1['command'] = "import"
      repo1['command_data'] = {
        "scmFullname" => "timgluz/mallet-lda",
        "scmranch"   => "master",
        "scmFilename" => "Gemfile"
      }
      repo1['project_files'] = {
        master: [{
          mode: "100644",
          path: "Gemfile",
          sha: "42716b93d440050ced0d10fdb8c696832e0aef89",
          size: 293,
          type: "blob",
          url: "https://api.github.com/repos/timgluz/lein-clr/git/blobs/42716b93d440050ced0d10fdb8c696832e0aef89"
        }]
      }
      action_url = "#{user_github_repos_path}/#{repo1[:_id]}"
      put action_url, repo1.as_document
      response.status.should eql(503)
    end

    it "should return updated repo model when importing succeeds" do
      project1.save.should be_true

      project1.projectdependencies.size.should > 0
      ProjectService.should_receive(:import_from_github).and_return(project1)
      repo1['command'] = "import"
      repo1['command_data'] = {
        "scmFullname" => "timgluz/mallet-lda",
        "scmBranch"   => "master",
        "scmFilename" => "Gemfile"
      }
      repo1['project_files'] = {
        master: [{
          mode: "100644",
          path: "Gemfile",
          sha: "42716b93d440050ced0d10fdb8c696832e0aef89",
          size: 293,
          type: "blob",
          url: "https://api.github.com/repos/timgluz/lein-clr/git/blobs/42716b93d440050ced0d10fdb8c696832e0aef89"
        }]
      }
      action_url = "#{user_github_repos_path}/#{repo1[:_id]}"
      put action_url, repo1.as_document

      response.status.should eql(200)
    end

    it "should remove project after imported project succeeds" do
      project1.save.should be_true
      ProjectService.should_receive( :destroy ).and_return(true)
      repo1['command'] = 'remove'
      repo1['command_data'] = {
        "scmFullname"  => "spec/repo1",
        "scmBranch"    => "master",
        "scmFilename"  => "Gemfile",
        "scmProjectId" => project1[:_id].to_s
      }
      repo1['project_files'] = {
        master: [{
          mode: "100644",
          path: "Gemfile",
          sha: "42716b93d440050ced0d10fdb8c696832e0aef89",
          size: 293,
          type: "blob",
          url: "https://api.github.com/repos/timgluz/lein-clr/git/blobs/42716b93d440050ced0d10fdb8c696832e0aef89"
        }]
      }
      action_url = "#{user_github_repos_path}/#{repo1[:_id]}"
      put action_url, repo1.as_document
      response.status.should eql(200)
    end
  end
end
