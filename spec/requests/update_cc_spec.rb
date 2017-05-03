require 'spec_helper'

describe "update credit card information" do

  let(:user){ FactoryGirl.create(:default_user) }

  context "logged in" do

    before :each do
      Plan.create_defaults
      User.delete_all
      UserNotificationSetting.delete_all
      post "/sessions", params: {:session => {:email => user.email, :password => user.password}}
      assert_response 302

      response.should redirect_to( projects_organisation_path( Organisation.first ) )
    end

    it "does not update the CC information because stripe token is missing" do
      orga = Organisation.first
      get cc_organisation_path( orga )
      assert_response :success
      assert_select "form[action=?]", update_cc_organisation_path( orga )

      post update_cc_organisation_path( orga ), params: {
        :plan => "plan_id",
        :type => BillingAddress::A_TYPE_INDIVIDUAL,
        :name => "Hans", :street => "Joko 1", :zip_code => "12345",
        :city => "Hambi", :country => "DE", :email => 'sup@ppe.de'}
      response.should redirect_to( cc_organisation_path(orga) )
      flash[:error].should eql("Stripe token is missing. Please contact the VersionEye Team.")
    end

    it "does not update the CC information because stripe customer is missing" do
      orga = Organisation.first
      get cc_organisation_path( orga )
      assert_response :success
      assert_select "form[action=?]", update_cc_organisation_path( orga )

      post update_cc_organisation_path( orga ), params: {:plan => "plan_id", :stripeToken => "token",
        :type => BillingAddress::A_TYPE_INDIVIDUAL,
        :name => "Hans", :street => "Joko 1", :zip_code => "12345",
        :city => "Hambi", :country => "DE", :email => 'sup@ppe.de'}
      response.should redirect_to( cc_organisation_path(orga) )
      flash[:error].should eql("Stripe customer is missing. Please contact the VersionEye Team.")
    end

  end

end
