require 'spec_helper'

describe "SignUp with GitHub" do

  it "github callback passes" do 
    
    get "/signup", nil, "HTTPS" => "on"
    assert_response :success
    assert_tag :tag => "span", :attributes => { :class => "btn_github login" }

    FakeWeb.register_uri(:get, "https://github.com/login/oauth/access_token?client_id=#{Settings.github_client_id}&client_secret=#{Settings.github_client_secret}&code=123", :body => "token=token_123")
    FakeWeb.register_uri(:get, "https://api.github.com/user?access_token=token_123", :body => "{\"id\": 1, \"email\": \"test@test.de\"}")
    
    get "/auth/github/callback?code=123"
    assert_response :success

  end

end
