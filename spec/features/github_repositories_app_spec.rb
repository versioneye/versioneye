require 'spec_helper'

describe "frontend APP for importing Github repositories", :js => true do

  let(:user_without_token) {(create(:default_user, username: "notoken",
                                    fullname: "No Token No",
                                    email: 'notoken@pupu.com'))}

  let(:user) {(create(:user, username: "pupujuku", fullname: "Pupu Juku",
                      email: 'juku@pupu.com', github_id: "123",
                      github_token: "asgasgasgas", github_scope: "repo"))}

  let(:repo1) {create(:github_repo, user_id: user.id.to_s,
                      github_id: 1, branches: ['master'],
                      language: 'ruby',
                      fullname: "spec/repo1", user_login: "a",
                      owner_login: "a", owner_type: "user")}
  let(:repo2) {create(:github_repo, user_id: user.id.to_s,
                      github_id: 2, branches: ['master'],
                      language: 'ruby',
                      fullname: "spec/repo2", user_login: "a",
                      owner_login: "a", owner_type: "user")}
  let(:project1) {build(:project_with_deps, deps_count: 3,
                      name: "spec_projectX", user_id: user.id.to_s)}


  describe "as authorized user without github token" do
    before :each do
      FakeWeb.allow_net_connect = true
      FakeWeb.clean_registry

      visit signin_path
      fill_in 'session[email]', with: user_without_token.email
      fill_in 'session[password]', with: user_without_token.password

      find('#sign_in_button').click
    end

    it "shows button for connecting Github account, when token is missing" do
      visit user_projects_github_repositories_path
      page.should have_content("Connect with GitHub to monitor your GitHub Repositories")
    end
  end

  describe "as authorized user", :firebug => true, js: true do
    before :each do
      FakeWeb.allow_net_connect = %r[^https?://127\.0\.0\.1]
      FakeWeb.register_uri(
        :get,
        %r|https://api\.github\.com/user|,
        [
          {status: [304, "Not modified"], body: {message: "Not modified"}.to_json},
          {body: %Q|{"public_repos": 0}|}
        ]
      )

      visit signin_path
      fill_in 'session[email]', with: user.email
      fill_in 'session[password]', with: user.password

      find('#sign_in_button').click
      page.should have_content('Packages I follow')
    end

    after :each do
      FakeWeb.allow_net_connect = true
      FakeWeb.clean_registry
    end

    # Needs some rework because of RabbitMQ
    # it "should show proper message when user dont have any repos" do
    #   GithubRepo.delete_all
    #   Github.count_user_repos(user) #use first reponse
    #   GitHubService.cached_user_repos( user )
    #   user.github_repos.all.count.should ==  0
    #   visit user_projects_github_repositories_path
    #   page.should_not have_content('Please enable Javascript to see content of the page.')

    #   sleep 5
    #   page.should have_content("We couldn't find any repositories in your GitHub account. If you think that's an error contact the VersionEye team.")
    # end

    it "should show list of github repos" do
      repo1[:imported_branches] = []
      repo1.save
      repo2[:imported_branches] = []
      repo2.save
      user.github_repos.all.count.should ==  2

      visit user_projects_github_repositories_path

      page.should_not have_content('Please enable Javascript to see content of the page.')

      page.should have_content( repo1.fullname )
      page.should have_content( repo2.fullname )
    end
  end
end
