require 'spec_helper'

describe "Payment Process" do

  before :all do
    User.destroy_all
    Plan.destroy_all
    @user = UserFactory.create_new
    Plan.create_default_plans
  end

  before :each do
    visit signin_path
    fill_in 'session[email]',    :with => @user.email
    fill_in 'session[password]', :with => @user.password
    click_button 'Sign In'
    page.should have_content("My Projects")
  end

  after :all do
    User.destroy_all
    Plan.destroy_all
  end

  describe "Empty Payment History", :js => true do
    it "shows correct message when there's no history" do
      visit "/settings/payments"
      have_css "#payment_history", text: "You dont have any Payment history"
    end
  end

  describe "update credit card information and book a plan", :js => true do

    it "updates the credit card information and books the first plan" do
      visit settings_plans_path
      Plan.count.should eq(4)
      page.should have_content(Plan.free_plan.name)
      page.should have_content(Plan.personal_plan.name)
      page.should have_content(Plan.business_small_plan.name)
      page.should have_content(Plan.business_normal_plan.name)

      click_button "#{Plan.personal_plan.name_id}_button"
      page.should have_content("Credit Card Information")
      page.should have_content("VersionEye doesn't store any Credit Card data")
      fill_in 'cardnumber', :with => "5105 1051 0510 5100"
      fill_in 'cvc',        :with => "777"
      fill_in 'month',      :with => "10"
      fill_in 'year',       :with => "2017"
      click_button 'Save'

      page.should have_content("Many Thanks. We just updated your plan.")
      user = User.find_by_email(@user.email)
      user.stripe_token.should_not be_nil
      user.stripe_customer_id.should_not be_nil
      user.plan.should_not be_nil
      user.plan.name_id.should eql(Plan.personal_plan.name_id)
    end

    it "upgrades the plan to business small" do
      visit settings_plans_path
      Plan.count.should eq(4)
      page.should have_content(Plan.free_plan.name)
      page.should have_content(Plan.personal_plan.name)
      page.should have_content(Plan.business_small_plan.name)
      page.should have_content(Plan.business_normal_plan.name)

      click_button "#{Plan.business_small_plan.name_id}_button"
      page.should have_content("We updated your plan successfully")
      user = User.find_by_email(@user.email)
      user.stripe_token.should_not be_nil
      user.stripe_customer_id.should_not be_nil
      user.plan.should_not be_nil
      user.plan.name_id.should eql(Plan.business_small_plan.name_id)
    end

  end

  describe "Payment History with content", :js => true  do
    it "shows correct list of invoices for current user" do
      visit settings_payments_path
      page.should_not have_content('Iniatilizing frontend app..')
      page.all(:css, "#payment_history")
      within('#payment_history') do
        page.all('a',  :text => 'View receipt')
        page.all('td', :text => 'Business Small')
        page.all('td', :text => '7.00 USD')
      end
    end
  end

end
