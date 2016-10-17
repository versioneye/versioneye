require 'spec_helper'

describe "registration" do

  context "no user" do

    it "signs_up successfully" do
      get "/signup", nil, "HTTPS" => "on"
      assert_response :success

      post "/users", { :user => {:fullname => "test123", :email => "test@test.de", :password => "test123", :terms => "1", :datenerhebung => "1"} }, "HTTPS" => "on"
      assert_response :success

      user = User.find_by_email("test@test.de")
      user.should_not be_nil
      user.verification.should_not be_nil
      user.fullname.should eql("test123")
      User.all.count.should eq(1)
    end

    it "don't sign_up because something is missing" do
      get "/signup", nil, "HTTPS" => "on"
      assert_response :success

      post "/users", {:user => {:fullname => "test123", :email => "test_bad@test.de", :password => "test123", :terms => "0", :datenerhebung => "0"}}, "HTTPS" => "on"
      assert_response 302
      response.should redirect_to( signup_path )
      User.all.count.should eq(0)
    end

    it "don't sign_up because email is not valid" do
      get "/signup", nil, "HTTPS" => "on"
      assert_response :success

      post "/users", {:user => {:fullname => "test123", :email => "test_bad@test.", :password => "test123", :terms => "1", :datenerhebung => "1"}}, "HTTPS" => "on"
      assert_response 302
      response.should redirect_to( signup_path )
      User.all.count.should eq(0)
    end

  end

  context "with user" do

    let(:user){ UserFactory.create_new() }

    it "login not successfully, because not activated" do
      # verification has a value. That means it is not activated!
      user.verification = "asgasfg"
      user.save

      get "/signin", nil, "HTTPS" => "on"
      assert_response :success

      post "/sessions", {:session => {:email => user.email, :password => user.password}}, {"HTTPS" => "on", 'HTTP_REFERER' => '/signin'}
      assert_response 302
      response.should redirect_to("/signin")
    end

    it "activates successfully and login successfully" do
      Plan.create_defaults
      user.verification = "asgasfg"
      user.save
      get "/users/activate/email/#{user.verification}", nil, "HTTPS" => "on"
      assert_response 200
      user_db = User.find_by_username( user.username )
      user_db.verification.should be_nil

      get "/signin", nil, "HTTPS" => "on"
      assert_response :success

      post "/sessions", {:session => {:email => user.email, :password => user.password}} , "HTTPS" => "on"
      assert_response 302
      response.should redirect_to( projects_organisation_path( Organisation.first ) )

      get new_user_project_path
      assert_response :success
    end

    it "login not successfully, because password is wrong" do
      get "/signin", nil, "HTTPS" => "on"
      assert_response :success

      post "/sessions", {:session => {:email => "test@test.de", :password => "test123asfgas"}}, {"HTTPS" => "on", 'HTTP_REFERER' => '/signin'}
      assert_response 302
      response.should redirect_to("/signin")
    end

  end

end
