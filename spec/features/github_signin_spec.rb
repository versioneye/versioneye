require 'spec_helper'

describe "Signin with GitHub" do

  let(:default_user){FactoryGirl.create(:default_user)}

  def logout_github
    visit "https://github.com/logout"
    click_button "Sign out"
  rescue => e
    p e
  end

  before :each do
    User.delete_all
    logout_github
  end

  after :each do
    logout_github
  end


  it "signs in new user with github, the email is not taken yet", js: true do
    User.all.count.should eql(0)

    visit signin_path
    page.has_css? 'button.btn-github'
    within("#sm_list") do
      click_button "Login with GitHub"
    end

    # GitHub Login Form
    fill_in "Username or email address", :with => Settings.instance.github_user
    fill_in 'Password', :with => Settings.instance.github_pass
    click_button 'Sign in'

    # Grant access
    if page.has_css?('button-primary') || page.has_css?('button.primary') || page.has_content?('Authorize application')
      click_button "Authorize application"
    end

    page.should have_content("I follow")
    User.all.count.should eql(1)
    user = User.first
    user.verification.should be_nil
    user.github_scope.should eq("repo,user:email")
  end

end
