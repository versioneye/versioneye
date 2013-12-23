require 'spec_helper'
describe "Signup with Bitbucket" do
  let(:user1){FactoryGirl.build(:user, email: "test@versioneye.com")}

  it "signup a new user with Bitbucket", js: true do
    visit signup_path
    page.has_css? 'button.btn-bitbucket'
    click_button "Login with Bitbucket"

    #log in with testuser's credentials
    within("form.login-form") do
      fill_in "Username", :with => Settings.bitbucket_username
      fill_in 'Password', :with => Settings.bitbucket_password
      click_button 'Log in'
    end
    
    #grant access
    if page.has_css? 'button.aui-button'
      click_button "Grant access"
    end

    page.should have_content "Almost done. We just need your email address."
    within("form.form-horizontal") do
      fill_in "Email", :with => user1[:email]
      check "terms"
      click_on "Sign Up"
    end

    User.all.count.should eql(1)
    u = User.all.first
    u.email.should eql(user1[:email])
    u.bitbucket_login.should eql("versioneye_test")
    u.bitbucket_token.should_not be_nil
    u.bitbucket_secret.should_not be_nil

  end
end
