require 'spec_helper'

describe "SignUp with GitHub" do

  before(:each) do
    User.destroy_all
  end

  after(:each) do
    User.destroy_all
  end

  it "github callback passes" do 
    
    get "/signup", nil, "HTTPS" => "on"
    assert_response :success
    assert_tag :tag => "span", :attributes => { :class => "btn_github login" }

    FakeWeb.register_uri(:get, "https://github.com/login/oauth/access_token?client_id=#{Settings.github_client_id}&client_secret=#{Settings.github_client_secret}&code=123", :body => "token=token_123")
    FakeWeb.register_uri(:get, "https://api.github.com/user?access_token=token_123", :body => "{\"id\": 1, \"email\": \"test@test.de\"}")
    
    get "/auth/github/callback?code=123"
    assert_response :success

    post "/auth/github/create", {:email => "test@test.de", :terms => "0" }, "HTTPS" => "on"
    response.should contain("You have to accept the Conditions of Use AND the Data Aquisition.")

    post "/auth/github/create", {:email => "test@test.de", :terms => "1" }, "HTTPS" => "on"
    assert_response :success
    response.should contain("Congratulation")

  end

end
