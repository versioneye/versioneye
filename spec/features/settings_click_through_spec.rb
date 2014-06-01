require 'spec_helper'

describe "Settings click through" do

  before :each do
    @user = UserFactory.create_new
    Plan.create_defaults
    visit signin_path
    fill_in 'session[email]',    :with => @user.email
    fill_in 'session[password]', :with => @user.password
    find('#sign_in_button').click
    page.should have_content("My Projects")
  end

  describe "test all links in the settings area", :js => true do

    it "clicks through all links without errors" do
      visit settings_profile_path
      page.should have_content("Profile")
      page.should have_content("Links")
      page.should have_content("E-Mails")
      page.should have_content("Plans & Pricing")
      page.should have_content("Billing Address")
      page.should have_content("Payments")
      page.should have_content("Connect")
      page.should have_content("Password")
      page.should have_content("Notification Center")
      page.should have_content("Privacy")
      page.should have_content("API")
      page.should have_content("Delete")

      visit settings_links_path
      page.should have_content("GitHub")
      page.should have_content("Twitter")

      click_link "E-Mails"
      page.should have_content("New E-Mail")

      click_link "Plans & Pricing"
      page.should have_content("Business / Small")

      click_link "Payments"
      page.should have_content("Payment History")
      page.should have_content("t have any Payment history")

      click_link "Billing Address"
      page.should have_content("Edit your billing address")

      click_link "Connect"
      page.should have_content("Connect with GitHub")

      click_link "Password"
      page.should have_content("New Password")

      click_link "Notification Center"
      page.should have_content("I want to receive the Newsletter about general news.")

      click_link "Privacy"
      page.should have_content("Who can see")

      click_link "API Key"
      page.should have_content("API Key")

      click_link "Delete"
      page.should have_content("Here you can delete this Account")
    end

  end

end
