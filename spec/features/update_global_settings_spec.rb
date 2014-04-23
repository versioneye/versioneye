require 'spec_helper'

describe "Update Global Settings" do

  before :each do
    AdminService.create_default_admin
  end

  describe "Login and update global settings", :js => true do

    it "logs in and updates global settings" do

      visit signin_path
      fill_in 'session[email]',    :with => "admin@admin.com"
      fill_in 'session[password]', :with => "admin"
      find('#sign_in_button').click
      page.should have_content("Settings")
      page.should have_content("Global Settings")

      click_link("Global Settings")
      page.should have_content("Global Server Settings")

      fill_in 'server_url',   :with => "http://union.on:900"
      fill_in 'server_host',  :with => "union.on"
      fill_in 'server_port',  :with => "900"
      click_button "Save"

      page.should have_content("successfully")

      Settings.instance.server_url.should eq("http://union.on:900")
      Settings.instance.server_host.should eq("union.on")
      Settings.instance.server_port.should == 900
    end

  end

end
