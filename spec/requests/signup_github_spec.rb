require 'spec_helper'

describe "SignUp with GitHub" do

  before(:each) do
    User.destroy_all
  end

  after(:each) do
    User.destroy_all
  end

  it "signup a new user with GitHub" do
    get signup_path, nil, "HTTPS" => "on"
    assert_response :success
    assert_tag :tag => "span", :attributes => { :class => "btn_github login" }

    FakeWeb.register_uri(:get, "https://github.com/login/oauth/access_token?client_id=#{Settings.github_client_id}&client_secret=#{Settings.github_client_secret}&code=123", :body => "token=token_123")
    FakeWeb.register_uri(:get, "https://api.github.com/user?access_token=token_123", :body => "{\"id\": 1, \"email\": \"test@test.de\"}")

    get "/auth/github/callback?code=123"
    assert_response :success

    post "/auth/github/create", {:email => "test@test.de", :terms => "0" }, "HTTPS" => "on"
    response.body.should match("You have to accept the Conditions of Use AND the Data Aquisition")

    post "/auth/github/create", {:email => "test@test.de", :terms => "1" }, "HTTPS" => "on"
    assert_response :success
    response.body.should match("Congratulation")
  end

  it "signin an existing user with GitHub. The GitHub ID is already in the database." do
    user = UserFactory.create_new
    user.github_id = "1"
    user.github_token = nil
    user.save

    FakeWeb.register_uri(:get, "https://github.com/login/oauth/access_token?client_id=#{Settings.github_client_id}&client_secret=#{Settings.github_client_secret}&code=123", :body => "token=token_123")
    FakeWeb.register_uri(:get, "https://api.github.com/user?access_token=token_123", :body => "{\"id\": 1, \"email\": \"test@test.de\"}")

    get "/auth/github/callback?code=123"
    assert_response 302
    response.should redirect_to( user_projects_path )

    user_db = User.find_by_email( user.email )
    user_db.github_token.should eql("token_123")
  end

  it "signin an existing user with GitHub. The email address is already in the database." do
    user = UserFactory.create_new

    FakeWeb.register_uri(:get, "https://github.com/login/oauth/access_token?client_id=#{Settings.github_client_id}&client_secret=#{Settings.github_client_secret}&code=123", :body => "token=token_123")
    FakeWeb.register_uri(:get, "https://api.github.com/user?access_token=token_123", :body => "{\"id\": 1585858, \"email\": \"#{user.email}\"}")

    get "/auth/github/callback?code=123"
    assert_response 302
    response.should redirect_to( user_projects_path )

    user_db = User.find_by_email( user.email )
    user_db.github_token.should eql("token_123")
    user_db.github_id.should eql("1585858")
  end

  it "connect a signed in user to his GitHub Account." do
    user = UserFactory.create_new
    user.github_id = nil
    user.github_token = nil
    user.github_scope = nil
    user.save

    post "/sessions", {:session => {:email => user.email, :password => "12345" }}, "HTTPS" => "on"
    assert_response 302
    response.should redirect_to( new_user_project_path )

    FakeWeb.register_uri(:get, "https://github.com/login/oauth/access_token?client_id=#{Settings.github_client_id}&client_secret=#{Settings.github_client_secret}&code=123", :body => "token=token_123")
    FakeWeb.register_uri(:get, "https://api.github.com/user?access_token=token_123", :body => "{\"id\": 1585858, \"email\": \"#{user.email}\"}")

    get "/auth/github/callback?code=123"
    assert_response 302
    response.should redirect_to("/settings/connect")

    user_db = User.find_by_email( user.email )
    user_db.github_token.should eql("token_123")
    user_db.github_id.should eql("1585858")
    user_db.github_scope.should be_nil
  end

end
