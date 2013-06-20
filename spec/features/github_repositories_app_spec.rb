require 'spec_helper'

FakeWeb.allow_net_connect = %r[^https?://127\.0\.0\.1]

describe "frontend APP for importing Github repositories", :js => true do
  let(:user) {(create(:user, username: "pupujuku", fullname: "Pupu Juku", 
                      email: 'juku@pupu.com'))}

  let(:repo1) {create(:github_repo, user_id: user.id.to_s, github_id: 1, 
                     fullname: "spec/repo1", user_login: "a", 
                     owner_login: "a", owner_type: "user")}
  let(:repo2) {create(:github_repo, user_id: user.id.to_s, github_id: 2, 
                     fullname: "spec/repo2", user_login: "a", 
                     owner_login: "a", owner_type: "user")}
  let(:project1) {build(:project_with_deps, deps_count: 3, 
                      name: "spec_projectX", user_id: user.id.to_s)}


  describe "as authorized user", :firebug => true do
    before :each do
      FakeWeb.register_uri(
        :get,
        %r|https://api\.github\.com/user|,
        {status: [304, "Not modified"], body: {message: "Not modified"}.to_json}
      )
      
      visit signin_path
      fill_in 'session[email]', with: user.email
      fill_in 'session[password]', with: user.password

      click_button 'Sign In'
      page.should have_content('My Projects')
    end

    it "should show proper message when user dont have any repos" do
      GithubRepo.delete_all

      GitHubService.should_receive(:cached_user_repos).and_return(user.github_repos) 
      user.github_repos.all.count.should ==  0
      visit user_projects_github_repositories_path

      page.should_not have_content('Please enable Javascript to see content of the page.')
      page.should have_content('No repositories!')
    end

    it "should show list of github repos" do
      repo1.save
      repo2.save
      user.github_repos.all.count.should ==  2

      visit user_projects_github_repositories_path

      page.should_not have_content('Please enable Javascript to see content of the page.')
      find('#github-repos').should have_css('.repo-container')
      page.should have_content(repo1.fullname)

    end

    it "should import selected github repos" do
      repo1.save
      repo2.save
      project1.save.should be_true

      project1.projectdependencies.size.should > 0
      ProjectService.should_receive(:import_from_github).and_return(project1) 
      
      visit user_projects_github_repositories_path
      page.should_not have_content('Please enable Javascript to see content of the page.')
    
      switch_selector = "#github-repo-switch-#{repo1.github_id}"
     
      
      #using_wait_time 5 do
      #  page.should have_text(repo1.fullname)
      #  page.should have_selector('select')
      #  page.should have_xpath('//div[@id="github-repos"]/div/div[@class="repo-container"]')
      #  page.should have_xpath('//div[@class="switch"]')
      #end
      
      #page.click_button("Off")
      #page.check switch_selector
      #page.should have_content("Please wait!")
 
      #using_wait_time 5 do
      #  find(switch_selector).find(".repo-labels").should have_css("Projects page")
      #end
    end

    it "should remove github project when user unselects switch" do
      repo1.save
      visit user_projects_github_repositories_path
      
      page.should_not have_content('Please enable Javascript to see content of the page.')
      switch_selector = "#github-repo-switch-#{repo1.github_id}"
      
      #p find(:css, switch_selector).text
      #page.should have_css(switch_selector)
      #page.check switch_selector

      #using_wait_time 3 do
      #  find(switch_selector).find(".repo-labels").should_not have_content("Projects page")
      #end
    end

  end
end
