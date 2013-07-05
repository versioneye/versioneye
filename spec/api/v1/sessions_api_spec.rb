require 'spec_helper'

describe SessionsApiV1 do
  describe "handling new sessions" do
    before(:each) do
      @sessions_url = "/api/v1/sessions"

      @test_user = UserFactory.create_new 999
      @user_api = Api.new user_id: @test_user.id,
                          api_key: Api.generate_api_key
      @user_api.save
    end

    after(:each) do
      @test_user.remove
      @user_api.remove
    end

    it "returns error when api token is missing" do
      post @sessions_url
      response.status.should == 400 #403
    end

    it "returns error when user submitted wrong token" do
      post @sessions_url, api_key: "123-abc-nil"
      response.status.should == 531
    end

    it "returns success when user gave correct API token" do
      post @sessions_url, api_key: @user_api.api_key
      response.status.should == 201

      get @sessions_url
      response_data = JSON.parse(response.body)
      response.status.should == 200
      response_data['api_key'].should eql(@user_api.api_key)
    end

    it "returns error when user tries to access profile page after signout" do
      
      delete @sessions_url

      get @sessions_url
      response.status.should == 401
    end
  end
end
