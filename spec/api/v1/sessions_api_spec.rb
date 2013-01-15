require 'spec_helper'

describe VersionEye::SessionsApi do
  describe "handling new sessions" do
    before(:each) do
      @test_user = UserFactory.create_new 
      @user_api = Api.new user_id: @test_user.id,
                          api_key: Api.generate_api_key
      @user_api.save
    end

    after(:each) do
      @test_user.delete
      @user_api.delete
    end

    it "returns error when api token is missing" do
      post "/v1/sessions"
      response.status.should == 403
    end

    it "returns error when user submitted wrong token" do
      post "/v1/sessions", api_key: "123-abc-nil"
      response.status.should == 531
    end

    it "returns success when user gave correct API token" do
      post "/v1/sessions", api_key: @user_api.api_key
      response.status.should == 201

      get "/v1/sessions"
      response_data = JSON.parse(response.body)
      response.status.should == 200
      response_data['api_key'].should eql(@user_api.api_key)
    end

    it "returns error when user tries to access profile page after signout" do
      
      delete "/v1/sessions"
      response.status.should == 200

      get "/v1/sessions"
      response.status.should == 401
    end
  end
end
