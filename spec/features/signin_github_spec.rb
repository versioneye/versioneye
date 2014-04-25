require 'spec_helper'

describe "Signin with GitHub" do

  before :each do
    User.delete_all
    visit "https://github.com/logout"
    click_button "Sign out"
  end

  after :each do
    visit "https://github.com/logout"
    click_button "Sign out"
  end


  it "signs in new user with github", js: true do
    User.all.count.should eql(0)

    visit signin_path
    page.has_css? 'button.btn-github'
    click_button "Login with GitHub"

    # GitHub Login Form
    fill_in "Username or Email", :with => Settings.instance.github_user
    fill_in 'Password', :with => Settings.instance.github_pass
    click_button 'Sign in'

    # Grant access
    if page.has_css? 'button.primary'
      click_button "Authorize application"
    end

    # 2nd page with email and terms.
    page.should have_content("Almost done.")
    find_field('email').value.should eq("test@versioneye.com")
    within("form.form-horizontal") do
      fill_in "email", :with => ""
      page.check "terms"
      click_button "Sign up"
    end

    page.should have_content("is mandatory")
    within("form.form-horizontal") do
      fill_in "email", :with => "test@versioneye.com"
      click_button "Sign up"
    end

    page.should have_content("You have to accept the Conditions")
    within("form.form-horizontal") do
      page.check "terms"
      click_button "Sign up"
    end

    page.should have_content("You follow 0")
    User.all.count.should eql(1)

    visit signout_path
    visit signin_path
    click_button "Login with GitHub"
    page.should have_content("You follow 0")

  end

end
