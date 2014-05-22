require 'spec_helper'

describe "update credit card information" do

  let(:user){ FactoryGirl.create(:default_user) }

  context "logged in" do

    before :each do
      post "/sessions", {:session => {:email => user.email, :password => user.password}}, "HTTPS" => "on"
      assert_response 302
      response.should redirect_to( user_packages_i_follow_path )
    end

    it "does not update the CC information because stripe token is missing" do
      get settings_creditcard_path
      assert_response :success
      assert_select "form[action=?]", settings_update_creditcard_path

      post settings_update_creditcard_path, {:plan => "plan_id", :name => "Hans", :street => "Joko 1", :zip_code => "12345", :city => "Hambi", :country => "Germany"}, "HTTPS" => "on"
      response.should redirect_to( settings_creditcard_path )
      flash[:error].should eql("Stripe token is missing. Please contact the VersionEye Team.")
    end

    it "does not update the CC information because stripe customer is missing" do
      get settings_creditcard_path
      assert_response :success
      assert_select "form[action=?]", settings_update_creditcard_path

      post settings_update_creditcard_path, {:plan => "plan_id", :stripeToken => "token", :name => "Hans", :street => "Joko 1", :zip_code => "12345", :city => "Hambi", :country => "Germany"}, "HTTPS" => "on"
      response.should redirect_to( settings_creditcard_path )
      flash[:error].should eql("Stripe customer is missing. Please contact the VersionEye Team.")
    end

  end

end
