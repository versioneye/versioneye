require 'spec_helper'

describe "Payment Process" do

  describe "Empty Payment History", :js => true do
    it "shows correct message when there's no history" do
      visit "/settings/payments"
      have_css "#payment_history", text: "t have any Payment history"
    end
  end

  describe "update credit card information and book a plan", :js => true do

    it "updates the credit card information and books the first plan" do
      user = UserFactory.create_new
      Plan.create_default_plans
      visit signin_path
      fill_in 'session[email]',    :with => user.email
      fill_in 'session[password]', :with => user.password
      find('#sign_in_button').click
      page.should have_content("My Projects")

      visit settings_plans_path
      Plan.count.should eq(4)
      page.should have_content(Plan.free_plan.name)
      page.should have_content(Plan.personal_plan.name)
      page.should have_content(Plan.business_small_plan.name)
      page.should have_content(Plan.business_normal_plan.name)


      ### It doesn't save because billing info is missing!

      click_button "#{Plan.personal_plan.name_id}_button"
      page.should have_content("Credit Card Information")
      page.should have_content("VersionEye doesn't store any Credit Card data")
      fill_in 'cardnumber', :with => "5105 1051 0510 5100"
      fill_in 'cvc',        :with => "777"
      fill_in 'month',      :with => "10"
      fill_in 'year',       :with => "2017"
      click_button 'Save'

      page.should have_content("Please complete the billing information.")


      ### Now it will save becasue billing info is complete

      fill_in 'name',       :with => "Hans Meier"
      fill_in 'street',     :with => "Johanniterstrasse 17"
      fill_in 'city',       :with => "Mannheim"
      fill_in 'zip_code',   :with => "68199"
      fill_in 'country',    :with => "Germany"

      fill_in 'cardnumber', :with => "5105 1051 0510 5100"
      fill_in 'cvc',        :with => "777"
      fill_in 'month',      :with => "10"
      fill_in 'year',       :with => "2017"
      click_button 'Save'

      page.should have_content("Many Thanks. We just updated your plan.")
      user = User.find_by_email( user.email )
      user.stripe_token.should_not be_nil
      user.stripe_customer_id.should_not be_nil
      user.plan.should_not be_nil
      user.plan.name_id.should eql(Plan.personal_plan.name_id)


      ### upgrades the plan to business normal

      visit pricing_path
      Plan.count.should eq(4)
      page.should have_content(Plan.free_plan.name)
      page.should have_content("You can monitor unlimited public, but no private repositories.")
      page.should have_content("Use the personal plan to track your private repositories.")
      page.should have_content("Use the business plans as an organization and take advantage of the advanced features.")

      click_button "business_normal_button"
      page.should have_content("We updated your plan successfully")
      user = User.find_by_email(user.email)
      user.stripe_token.should_not be_nil
      user.stripe_customer_id.should_not be_nil
      user.plan.should_not be_nil
      user.plan.name_id.should eql(Plan.business_normal_plan.name_id)

      ### upgrades the plan to business small

      visit settings_plans_path
      Plan.count.should eq(4)
      page.should have_content(Plan.free_plan.name)
      page.should have_content(Plan.personal_plan.name)
      page.should have_content(Plan.business_small_plan.name)
      page.should have_content(Plan.business_normal_plan.name)

      click_button "#{Plan.business_small_plan.name_id}_button"
      page.should have_content("We updated your plan successfully")
      user = User.find_by_email(user.email)
      user.stripe_token.should_not be_nil
      user.stripe_customer_id.should_not be_nil
      user.plan.should_not be_nil
      user.plan.name_id.should eql(Plan.business_small_plan.name_id)


      ### shows correct list of invoices for current user

      visit settings_payments_path
      page.should_not have_content('Iniatilizing frontend app..')
      page.all(:css, "#payment_history")
      using_wait_time 10 do
        find_by_id("invoice_table")
        page.should have_content("View receipt")
        page.should have_content("Personal")
        page.should have_content("3.00 USD")
        # The Business Small plan is the upcoming invoice
      end


      ### shows the receipt

      user = User.find_by_email(user.email)
      customer = StripeService.fetch_customer user.stripe_customer_id
      invoices = customer.invoices
      invoices.count.should eq(1)
      invoice = invoices.first

      visit settings_receipt_path( invoice.id )
      page.should have_content("This is a receipt for your VersionEye subscription.")
      page.should have_content("Personal")
      page.should have_content("3.00 USD")
    end

  end

end
