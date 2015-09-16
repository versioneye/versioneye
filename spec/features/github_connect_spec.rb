require 'spec_helper'

describe "Connect with GitHub" do

  let(:user) {FactoryGirl.create( :github_user )}

  before :each do
    User.delete_all
    visit "https://github.com/logout"
    click_button "Sign out"
  end

  after :each do
    visit "https://github.com/logout"
    click_button "Sign out"
  end


  it "connect existing user with github", js: true do
    user.save
    User.all.count.should eql(1)
    user = User.first
    user.github_token = nil
    user.github_id = nil
    user.save.should be_truthy

    visit signin_path
    within("form.form-horizontal") do
      fill_in "Email", with: user[:email]
      fill_in "Password", with: 'password'
      click_on "Sign in"
    end

    visit settings_connect_path
    click_link "Connect with GitHub"

    # GitHub Login Form
    fill_in "Username or email address", :with => Settings.instance.github_user
    fill_in 'Password', :with => Settings.instance.github_pass
    click_button 'Sign in'

    if page.has_css?('button-primary') || page.has_css?('button.primary') || page.has_content?("Authorize application")
      click_button "Authorize application"
    end

    page.should have_content "Connected"
    page.should have_content "scopes: repo,user:email"

    user = User.first
    user.github_token.should_not be_nil
    user.github_id.should_not be_nil
  end

end
