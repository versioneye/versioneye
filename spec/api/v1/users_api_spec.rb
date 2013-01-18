require 'spec_helper'

describe VersionEye::UsersApi do
  describe "not authorized user tries to access to user data" do
    it "returns authorization error when asking user's profile" do
      get '/v1/me'
      response.status.should == 401
    end
    
    it "returns authorization error when asking user's favorites" do
      get '/v1/me/favorites'
      response.status.should == 401
    end

    it "returns authorixation error when asking user's comments" do
      get '/v1/me/comments'
      response.status.should == 401
    end

    it "returns authorization error when asking user's notifications" do
      get '/v1/me/comments'
      response.status.should == 401
    end

    it "returns authorization errow when accessing other user data" do
      get '/v1/users/reiz'
      response.status.should == 401

      get '/v1/users/reiz/favorites'
      response.status.should == 401

      get '/v1/users/reiz/comments'
      response.status.should == 401
    end
  end

  describe "authorized user access own data" do
    before(:each) do
      @test_user = UserFactory.create_new
      @user_api =  ApiFactory.create_new(@test_user)

      #set up active session
      post '/v1/sessions', :api_key => @user_api.api_key
    end

    after(:each) do
      @test_user.delete
    end

    it "returns user's miniprofile" do
      get '/v1/me'
      response.status.should == 200
    end
  end

  describe "authorized user access notifications" do
    before(:each) do
      @test_user = UserFactory.create_new
      @user_api = ApiFactory.create_new @test_user
    end

    after(:each) do
      @test_user.remove
      @user_api.remove
    end

    it "should return empty dataset when there's no notifications" do
      get "/v1/me/notifications", :api_key => @user_api.api_key
      response.status.should == 200
      response_data = JSON.parse(response.body)
      response_data["user"]["username"].should eql(@test_user.username)
      response_data["unread"].should == 0
      response_data["notifications"].length.should == 0
    end

    it "should return correct notifications when we add them" do
      new_notification = NotificationFactory.create_new @test_user
      get "/v1/me/notifications", :api_key => @user_api.api_key
      response.status.should == 200
      response_data = JSON.parse(response.body)
      response_data["unread"].should == 1
      response_data["notifications"].length.should == 1
      msg = response_data["notifications"].shift
      msg["version"].should eql(new_notification.version)
    end
  end

end
