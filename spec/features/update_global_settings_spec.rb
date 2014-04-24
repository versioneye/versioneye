require 'spec_helper'

describe "Update Global Settings" do

  before :each do
    AdminService.create_default_admin

    visit signin_path
    fill_in 'session[email]',    :with => "admin@admin.com"
    fill_in 'session[password]', :with => "admin"
    find('#sign_in_button').click
    page.should have_content("Settings")
    page.should have_content("Global Settings")
  end

  describe "Login and update global settings", :js => true do

    it "updates global settings" do
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

    it "updates github settings" do
      click_link("GitHub Settings")
      page.should have_content("GitHub Settings")

      Settings.instance.github_api_url.should eq("https://api.github.com")

      fill_in 'github_base_url'     , :with => "http://gitomat.it"
      fill_in 'github_api_url'      , :with => "http://api.gitomat.it"
      fill_in 'github_client_id'    , :with => "gasfgasi888a"
      fill_in 'github_client_secret', :with => "gal898su8uuuhbn"
      click_button "Save"

      page.should have_content("successfully")

      Settings.instance.github_base_url.should eq("http://gitomat.it")
      Settings.instance.github_api_url.should eq("http://api.gitomat.it")
      Settings.instance.github_client_id.should eq("gasfgasi888a")
      Settings.instance.github_client_secret.should eq("gal898su8uuuhbn")
    end

    it "updates nexus settings" do
      click_link("Sonatype Nexus")
      page.should have_content("Nexus Settings")

      Settings.instance.nexus_url.should eq("http://nexus.pro")

      fill_in 'nexus_url', :with => "http://nixen.nexus.orp"
      click_button "Save"

      page.should have_content("successfully")

      Settings.instance.nexus_url.should eq("http://nixen.nexus.orp")
    end

  end

end
