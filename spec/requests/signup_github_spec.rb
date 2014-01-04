require 'spec_helper'
require 'vcr'
require 'webmock'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes/'
  c.ignore_localhost = true
  c.hook_into :webmock # or :fakeweb
end

describe "SignUp with GitHub" do

  before :all do
    FakeWeb.allow_net_connect = true
    WebMock.allow_net_connect!
  end

  after :all do
    WebMock.allow_net_connect!
    FakeWeb.allow_net_connect = true
    FakeWeb.clean_registry
  end


  it "signup a new user with GitHub" do
    get signup_path, nil, "HTTPS" => "on"
    assert_response :success
    assert_tag :tag => "button", :attributes => { :class => "btn btn-github btn-large btn-signin" }

    VCR.use_cassette('github_signup', :allow_playback_repeats => true) do
      get "/auth/github/callback?code=003f290db37ad2ceefc9"
      assert_response :success
      response.body.should match("Almost done. We just need your email address.")

      post "/auth/github/create", {:email => "test@versioneye.com", :terms => "0" }, "HTTPS" => "on"
      response.body.should match("You have to accept the Conditions of Use AND the Data Aquisition")

      post "/auth/github/create", {:email => "test@versioneye.com", :terms => "1" }, "HTTPS" => "on"
      assert_response :success
      response.body.should match("Congratulation")
    end
  end

  it "sign in an existing user with GitHub. The GitHub ID is already in the database." do
    user = UserFactory.create_new
    user.github_id = "652130"
    user.github_token = nil
    user.save.should be_true
    VCR.use_cassette('github_signup', :allow_playback_repeats => true) do
      get "/auth/github/callback?code=003f290db37ad2ceefc9"
      response.should redirect_to( user_packages_i_follow_path )
      user_db = User.find_by_email( user.email )
      user_db.github_token.should eql("3974100548430f742b9716b2e26ba73437fe8028")
    end
  end

  it "connect a signed in user to his GitHub Account." do
    user = UserFactory.create_new
    user.github_id = nil
    user.github_token = nil
    user.github_scope = nil
    user.save

    post "/sessions", {:session => {:email => user.email, :password => "12345" }}, "HTTPS" => "on"
    assert_response 302
    response.should redirect_to( user_packages_i_follow_path )

    VCR.use_cassette('github_signup', :allow_playback_repeats => true) do
      get "/auth/github/callback?code=003f290db37ad2ceefc9"
      assert_response 302
      response.should redirect_to("/settings/connect")
      user_db = User.find_by_email( user.email )
      user_db.github_token.should eql("3974100548430f742b9716b2e26ba73437fe8028")
      user_db.github_id.should eql("652130")
      user_db.github_scope.should eql("no_scope")
    end
  end
end
