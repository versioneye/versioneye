require 'spec_helper'
# require 'capybara/rspec'

describe "Update Credit Card Information" do

  before(:each) do
    User.destroy_all
    Plan.create_default_plans
    @user1 = UserFactory.create_new(100, true)
    @user1.save
  end

  after(:each) do
    User.destroy_all
    Plan.destroy_all
  end

  it "updates the credit card information successfully" do
    get signin_path, nil, "HTTPS" => "on"
    assert_response :success

    post sessions_path, {:session => {:email => @user1.email, :password => "12345"}}, "HTTPS" => "on"
    assert_response 302
    response.should redirect_to( user_projects_path )

    get settings_plans_path, nil, "HTTPS" => "on"
    assert_response :success
    Plan.count.should eq(4)
    response.should contain("Plans & Pricing")
    response.should contain("Personal")
    # click_button("02_personal_button")

    post settings_updateplan_path, {:plan => Plan::A_PLAN_PERSONAL}, "HTTPS" => "on"
    assert_response :success
    response.should contain("Credit Card Information")
    page.find_by_id("plan").value.should eql(Plan::A_PLAN_PERSONAL)
    # response.should contain(Plan::A_PLAN_PERSONAL)
  end

  # it "do some tests" do
  #   visit signin_path
  #   within("#session") do
  #     fill_in 'email',    :with => @user1.email
  #     fill_in 'password', :with => "12345"
  #   end
  #   click_link 'Sign In'
  #   page.should have_content 'Success'
  # end


end
