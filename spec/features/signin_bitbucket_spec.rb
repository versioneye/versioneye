require 'spec_helper'

def connect_user_account(user)
  describe "connect" do
    it 'connects user with bitbucket', js: true do
      visit signin_path
      page.has_css? 'button.btn-bitbucket'
      click_button "Login with Bitbucket"

      #when bitbucket asks testuser's credentials
      within("form.login-form") do
        fill_in "Username", :with => Settings.instance.bitbucket_username
        fill_in 'Password', :with => Settings.instance.bitbucket_password
        click_button 'Log in'
      end
      #grant access
      if page.has_css? 'button.aui-button'
        click_button "Grant access"
      end
    end
  end

  User.where(email: user[:email]).shift #returns updated user
end

describe "Signin with Bitbucket" do

  let(:user1){FactoryGirl.create(:bitbucket_user,
                                 bitbucket_id: "versioneye_test")}

  before :each do
    User.delete_all
    visit 'https://bitbucket.org/account/signout/'
    page.has_content? 'Unlimited private code repositories'
  end

  after :each do
    visit 'https://bitbucket.org/account/signout/'
    page.has_content? 'Unlimited private code repositories'
  end


  it "signs already existing users in and updates info", js: true do
    user1.save
    User.all.count.should eql(1)

    visit signin_path
    page.has_css? 'button.btn-bitbucket'
    click_button "Login with Bitbucket"

    #when bitbucket asks testuser's credentials
    within("form.login-form") do
      fill_in "Username", :with => Settings.instance.bitbucket_username
      fill_in 'Password', :with => Settings.instance.bitbucket_password
      click_button 'Log in'
    end
    #grant access
    if page.has_css? 'button.aui-button'
      click_button "Grant access"
    end

    current_path.should == user_packages_i_follow_path
    User.all.count.should eql(1)
    u = User.all.first
    u.bitbucket_token.should_not be_nil
    u.bitbucket_secret.should_not be_nil
    u.username.should eql('hans_tanz')
    u.bitbucket_login.should eql(user1[:bitbucket_id])

  end
end
