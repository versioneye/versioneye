require 'spec_helper'

describe "user_email" do

  context "add aditional email to user" do

    before :each do
      User.delete_all
      UserNotificationSetting.delete_all
    end

    it "signs_up successfully and adds an additional email address to the account" do
      get "/signup"
      assert_response :success

      post "/users", params: { :user => {:fullname => "test123", :email => "test@test.de", :password => "test123", :terms => "1", :datenerhebung => "1"} }
      assert_response :success

      email = "test@test.de"
      email_2 = "ta+ta@versioneye.com"

      user = User.find_by_email( email )
      user.should_not be_nil
      user.verification.should_not be_nil
      user.fullname.should eql("test123")
      User.all.count.should eq(1)

      get "/users/activate/email/#{user.verification}"
      assert_response 200

      user = User.find_by_email( email )
      user.verification.should be_nil

      user_email = UserEmail.new
      user_email.email = email_2
      user_email.user_id = user._id.to_s
      user_email.create_verification
      user_email.save.should be_truthy

      get "/users/activate/email/wrong_verifaction_code"

      user_email = UserEmail.find_by_email( email_2 )
      user_email.should_not be_nil
      user_email.verification.should_not be_nil

      get "/users/activate/email/#{user_email.verification}"

      user_email = UserEmail.find_by_email( email_2 )
      user_email.should_not be_nil
      user_email.verification.should be_nil
    end

  end

end
