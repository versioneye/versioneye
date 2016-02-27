require 'spec_helper'

describe "Login Area for Admin" do

  before :each do
    AdminService.create_default_admin
  end

  describe "Login and update email settings", :js => true do

    it "logs in and updates email settings" do

      visit signin_path
      fill_in 'session[email]',    :with => "admin"
      fill_in 'session[password]', :with => "admin"
      find('#sign_in_button').click

      page.driver.browser.manage.window.maximize
      page.should have_content("Settings")
      page.should have_content("Email Server Settings")

      fill_in 'sender_name',   :with => "Hasso"
      fill_in 'sender_email',  :with => "hasso@platto.de"
      fill_in 'address',   :with => "smtp.gmail.com"
      fill_in 'port',  :with => "9090"
      fill_in 'username',  :with => "hodo"
      fill_in 'password',  :with => "Frodo"
      fill_in 'domain',  :with => "game.of.throne"
      fill_in 'Authentication',  :with => "PLOIN"
      click_button "Save"

      es = EmailSettingService.email_setting
      es.sender_name.should eq("Hasso")
      es.sender_email.should eq("hasso@platto.de")
      es.address.should eq("smtp.gmail.com")
      es.port.should == 9090
      es.username.should eq("hodo")
      es.domain.should eq("game.of.throne")

      page.should have_content("Email settings updated")
    end

  end

end
