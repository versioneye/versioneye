require 'spec_helper'

describe "Payment Process" do

  describe "Empty Payment History", :js => true do
    it "shows correct message when there's no history" do
      visit "/settings/payments"
      have_css "#payment_history", text: "t have any payment history"
    end
  end

  describe "update credit card information and book a plan", :js => true do

    it "updates the credit card information and books the first plan" do
      user = UserFactory.create_new
      Plan.create_defaults
      visit signin_path
      fill_in 'session[email]',    :with => user.email
      fill_in 'session[password]', :with => user.password
      find('#sign_in_button').click
      page.should have_content("Why not following the most popular packages")

      visit settings_plans_path
      Plan.count.should eq(7)
      page.should have_content(Plan.free_plan.name)
      page.should have_content(Plan.small.name)
      page.should have_content(Plan.medium.name)
      page.should have_content(Plan.xlarge.name)


      ### It doesn't save because billing info is missing!

      click_button "#{Plan.small.name_id}_button"
      page.should have_content("Credit Card Information")
      page.should have_content("VersionEye doesn't store any Credit Card data")
      fill_in 'cardnumber', :with => "5105 1051 0510 5100"
      fill_in 'cvc',        :with => "777"
      fill_in 'month',      :with => "10"
      fill_in 'year',       :with => "2017"
      click_button 'Submit'

      sleep 5

      page.should have_content("Please complete the billing information")

      ### Now it will save becasue billing info is complete

      fill_in 'name',       :with => "Hans Meier"
      fill_in 'street',     :with => "Johanniterstrasse 17"
      fill_in 'city',       :with => "Mannheim"
      fill_in 'zip_code',   :with => "68199"
      find('#country').find(:xpath, "option[@value = 'DE']").select_option

      fill_in 'cardnumber', :with => "5105 1051 0510 5100"
      fill_in 'cvc',        :with => "777"
      fill_in 'month',      :with => "10"
      fill_in 'year',       :with => "2017"
      click_button 'Submit'

      page.should have_content("Many Thanks. We just updated your plan.")
      user = User.find_by_email( user.email )
      user.stripe_token.should_not be_nil
      user.stripe_customer_id.should_not be_nil
      user.plan.should_not be_nil
      user.plan.name_id.should eql(Plan.small.name_id)


      ### upgrades the plan to business normal

      visit pricing_path
      Plan.count.should eq(7)
      page.should have_content("VersionEye allows you to monitor your open source projects for free")

      sleep 3

      click_button "#{Plan.xlarge.name_id}_button"

      sleep 3

      page.should have_content("We updated your plan successfully")
      user = User.find_by_email(user.email)
      user.stripe_token.should_not be_nil
      user.stripe_customer_id.should_not be_nil
      user.plan.should_not be_nil
      user.plan.name_id.should eql(Plan.xlarge.name_id)


      ### upgrades the plan to business small

      visit settings_plans_path
      Plan.count.should eq(7)
      page.should have_content(Plan.free_plan.name)
      page.should have_content(Plan.small.name)
      page.should have_content(Plan.medium.name)
      page.should have_content(Plan.xlarge.name)

      click_button "#{Plan.medium.name_id}_button"
      page.should have_content("We updated your plan successfully")
      user = User.find_by_email(user.email)
      user.stripe_token.should_not be_nil
      user.stripe_customer_id.should_not be_nil
      user.plan.should_not be_nil
      user.plan.name_id.should eql(Plan.medium.name_id)


      ### shows correct list of invoices for current user

      receipt = Receipt.new({
         :type => "private",
         :name => 'Jack',
         :street => 'Jack-Street 1',
         :zip => '59811',
         :city => 'Mannheim',
         :country => 'Germany',
         :receipt_nr => 124,
         :invoice_id => 'tx_858573',
         :user => user,
         :invoice_date => Date.new,
         :period_start => Date.new,
         :period_end   => Date.new,
         :total => 1200,
         :currency => 'eur',
         :paid => true,
         :closed => true,
        })
      expect( receipt.save ).to be_truthy

      visit settings_payments_path
      page.all(:css, "#payment_history")
      using_wait_time 2 do
        find_by_id("invoice_table")
        page.should have_content(".pdf")
        page.should have_content("#{Plan.small.price}.00 EUR")
      end


      ### shows the receipt

      user = User.find_by_email(user.email)
      customer = StripeService.fetch_customer user.stripe_customer_id
      invoices = customer.invoices
      invoices.count.should eq(1)
      invoice = invoices.first
      visit settings_receipt_path( invoice.id )
    end

  end

end
