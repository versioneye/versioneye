require 'spec_helper'
describe "Signup with Bitbucket" do
  let(:user1){FactoryGirl.build(:user, email: "test@versioneye.com")}

  before :each do
    User.all.delete_all
    visit 'https://bitbucket.org/account/signout/'
    page.has_content? 'Unlimited private code repositories'
  end

  after :each do
    visit 'https://bitbucket.org/account/signout/'
    page.has_content? 'Unlimited private code repositories'
  end


  it "signup a new user with Bitbucket", js: true do
    visit signup_path
    page.has_css? 'button.btn-bitbucket'
    click_button "Login with Bitbucket"

    #log into Bitbucket when required
    find("form.login-form").visible?
    within("form.login-form") do
      fill_in "Username", :with => Settings.instance.bitbucket_username
      fill_in 'Password', :with => Settings.instance.bitbucket_password
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
      click_on "Sign up"
    end

    User.all.count.should eql(1)
    u = User.all.first
    u.email.should eql(user1[:email])
    u.bitbucket_login.should eql("versioneye_test")
    u.bitbucket_token.should_not be_nil
    u.bitbucket_secret.should_not be_nil

  end
end
