require 'spec_helper'

describe "Billing address" do

  before :each do
    @user = UserFactory.create_new
    Plan.create_defaults
    visit signin_path
    fill_in 'session[email]',    :with => @user.email
    fill_in 'session[password]', :with => @user.password
    find('#sign_in_button').click
    page.driver.browser.manage.window.maximize
  end

  describe "update the billing address", :js => true do

    it "updates the billing address" do
      orga = Organisation.first
      visit billing_address_organisation_path(orga)
      page.should have_content("Billing address")

      click_link "Billing address"
      page.should have_content("Edit your billing address")

      fill_in 'name',       :with => "Hans Meier"
      fill_in 'street',     :with => "Johanniterstrasse 17"
      fill_in 'city',       :with => "Mannheim"
      fill_in 'zip_code',   :with => ""
      find('#country').find(:xpath, "option[@value = 'DE']").select_option
      click_button 'Save'

      page.should have_content("An error occured. Please try again.")
      page.should have_content("is mandatory")

      fill_in 'name',       :with => "Hans Meier"
      fill_in 'street',     :with => "Johanniterstrasse 17"
      fill_in 'city',       :with => "Mannheim"
      fill_in 'zip_code',   :with => "68111"
      find('#country').find(:xpath, "option[@value = 'DE']").select_option
      page.should have_content("An error occured. Please try again.")
      page.should have_content("is mandatory")

      fill_in 'name',       :with => "Hans Meier"
      fill_in 'street',     :with => "Johanniterstrasse 17"
      fill_in 'city',       :with => "Mannheim"
      fill_in 'zip_code',   :with => "68111"
      fill_in 'email',      :with => "support@customer.de"
      find('#country').find(:xpath, "option[@value = 'DE']").select_option
      click_button 'Save'

      page.should have_content("Your billing address was saved successfully.")
    end

  end

end
