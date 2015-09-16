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
    logout_github
  end

  after :each do
    logout_github
  end

  it 'signs in a new user with github, email is already taken', js: true do
    User.all.count.should eql(0)
    default_user.email = "test1@versioneye.com"
    default_user.save
    User.all.count.should eql(1)
    ue = UserEmail.new(:user_id => default_user.ids, :email => "test@versioneye.com")
    expect( ue.save ).to be_truthy

    visit signin_path
    page.has_css? 'button.btn-github'
    within("#sm_list") do
      click_button "Login with GitHub"
    end

    # find("#sm_github").click
    # click_button "Login with GitHub"

    # GitHub Login Form
    fill_in "Username or email address", :with => Settings.instance.github_user
    fill_in 'Password', :with => Settings.instance.github_pass
    click_button 'Sign in'

    # Grant access
    if page.has_css?('button-primary') || page.has_css?('button.primary') || page.has_content?("Authorize application")
      click_button "Authorize application"
    end

    # 2nd page with email and terms.
    page.should have_content("Almost done.")
    page.should have_content("The email address is already taken")
    find_field('email').value.should eq("test@versioneye.com")
    within("form.form-horizontal") do
      fill_in "email", :with => ""
      page.check "terms"
      click_button "Sign up"
    end

    page.should have_content("is mandatory")
    within("form.form-horizontal") do
      fill_in "email", :with => "test_2@versioneye.com"
      click_button "Sign up"
    end

    page.should have_content("You have to accept the Conditions")
    within("form.form-horizontal") do
      page.check "terms"
      click_button "Sign up"
    end

    page.should have_content("GitHub Repositories")
    User.all.count.should eql(2)

    visit signout_path
    visit signin_path
    click_button "Login with GitHub"
    page.should have_content("GitHub Repositories")
  end

end
