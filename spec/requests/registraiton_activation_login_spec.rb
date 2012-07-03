require 'spec_helper'

describe "registration" do

  it "signs_up successfully" do
    get "/signup"
    assert_response :success

    post "/users", :user => {:fullname => "test123", :email => "test@test.de", :password => "test123", :terms => "1", :datenerhebung => "1"}
    assert_response :success

    user = User.find_by_email("test@test.de")
    user.should_not be_nil
    user.verification.should_not be_nil
    user.fullname.should eql("test123")
  end

  it "login not successfully, because not activated" do 
    get "/signin"
    assert_response :success

    post "/sessions", :session => {:email => "test@test.de", :password => "test123"}
    assert_response 302
    response.should redirect_to("/signin")
  end

  it "activates successfully" do 
    user = User.find_by_email("test@test.de")
    user.should_not be_nil
    get "/users/activate/#{user.verification}"
    assert_response 302
    response.should redirect_to("/signin")
    user = User.find_by_email("test@test.de")
    user.verification.should be_nil
  end

  it "login successfully" do 
    get "/signin"
    assert_response :success

    post "/sessions", :session => {:email => "test@test.de", :password => "test123"}
    assert_response 302
    response.should redirect_to("/news")

    get "/news"
    assert_response :success
  end

  it "login not successfully, because password is wrong" do 
    get "/signin"
    assert_response :success

    post "/sessions", :session => {:email => "test@test.de", :password => "test123asfgas"}
    assert_response 302
    response.should redirect_to("/signin")
    user = User.find_by_email("test@test.de")
    user.remove
  end

  it "don't sign_up because something is missing" do
    get "/signup"
    assert_response :success

    post "/users", :user => {:fullname => "test123", :email => "test_bad@test.de", :password => "test123", :terms => "0", :datenerhebung => "0"}
    assert_response :success
    
    user = User.find_by_email("test_bad@test.de")
    user.should be_nil
  end

  it "don't sign_up because email is not valid" do
    get "/signup"
    assert_response :success

    post "/users", :user => {:fullname => "test123", :email => "test_bad@test.", :password => "test123", :terms => "1", :datenerhebung => "1"}
    assert_response :success

    user = User.find_by_email("test_bad@test.de")
    user.should be_nil
  end

end