require 'spec_helper'

describe "Update Credit Card Information" do

  before(:each) do
    User.destroy_all

    @user1 = UserFactory.create_new(100, true)
    @user1.save
  end

  after(:each) do
    User.destroy_all
  end

  it "updates the credit card information successfully" do
    get signin_path, nil, "HTTPS" => "on"
    assert_response :success

    post sessions_path, {:session => {:email => @user1.email, :password => "12345"}}, "HTTPS" => "on"
    assert_response 302
    response.should redirect_to( user_projects_path )

    get settings_plans_path, nil, "HTTPS" => "on"
    assert_response :success
    response.should contain("Plans & Pricing")



  end

end
