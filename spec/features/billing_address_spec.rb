require 'spec_helper'

describe "Billing Address" do

  before :each do
    @user = UserFactory.create_new
    Plan.create_defaults
    visit signin_path
    fill_in 'session[email]',    :with => @user.email
    fill_in 'session[password]', :with => @user.password
    find('#sign_in_button').click
    page.should have_content("I follow")
  end

  describe "update the billing address", :js => true do

    it "updates the billing address" do
      visit settings_profile_path
      page.should have_content("Billing Address")

      click_link "Billing Address"
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
      click_button 'Save'

      page.should have_content("Your billing address was saved successfully.")
    end

  end

end
