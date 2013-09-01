require 'spec_helper'

describe User do

  before(:each) do
    @user = User.new
    @user.fullname = "Hans Tanz"
    @user.username = "hanstanz"
    @user.email = "hans@tanz.de"
    @user.password = "password"
    @user.salt = "salt"
    @user.github_id = "github_id_123"
    @user.terms = true
    @user.datenerhebung = true
    @user.save

    UserFactory.create_defaults
    BillingAddress.destroy_all
  end

  describe "fetch_or_create_billing_address" do
    it "returns username as default param" do
      billing = @user.fetch_or_create_billing_address
      billing.should_not be_nil
      billing.name.should eql( @user.fullname )
      BillingAddress.count.should eq(1)

      billing_2 = @user.fetch_or_create_billing_address
      billing_2.should_not be_nil
      billing_2.id.to_s.should eql( billing.id.to_s )
      BillingAddress.count.should eq(1)
    end
  end

end
