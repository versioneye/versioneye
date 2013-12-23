require 'spec_helper'

describe "Connect with Bitbucket" do
  
  let(:user1){FactoryGirl.create(:default_user)}

  it "connects Bitbucket account for authorized user", js: true do
    user1.save
    User.all.count.should eql(1)

    visit signin_path
    within("form.form-horizontal") do
      fill_in "Email", with: user1[:email]
      fill_in "Password", with: 'password'
      click_on "Sign In"
    end

    visit settings_connect_path
    page.has_content? 'Connect with GitHub and others'
    click_on "Connect with Bitbucket"

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

    current_path.should == settings_connect_path
    page.has_content? 'Connected'

    User.all.count.should eql(1)
    u = User.all.first
    u.bitbucket_token.should_not be_nil
    u.bitbucket_secret.should_not be_nil
    u.username.should eql(u.bitbucket_id)
  end
end
