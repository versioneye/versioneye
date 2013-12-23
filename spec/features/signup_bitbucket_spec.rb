require 'spec_helper'
require 'vcr'
require 'webmock'
require 'capybara/rails'
require 'capybara/rspec'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes/'
  c.ignore_localhost = true
  c.hook_into :webmock
end

describe "Signup with Bitbucket" do

  before :all do
    FakeWeb.allow_net_connect = true
    WebMock.allow_net_connect!
  end

  after :all do
    WebMock.allow_net_connect!
    FakeWeb.allow_net_connect = true
    FakeWeb.clean_registry
  end


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

    #User.all.count.should eql(1)
    p User.all.first
  end
end
