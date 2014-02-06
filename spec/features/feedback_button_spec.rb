require 'spec_helper'

describe "Feedback Button" do

  describe "test all links in the settings area", :js => true do

    it "Tests the functionality fo the feebackbutton" do
      visit root_path
      page.should have_content("Feedback")
      click_link "Feedback"
      page.should have_content("Please login to give us feedback")

      user = UserFactory.create_new
      Plan.create_default_plans

      visit signin_path
      fill_in 'session[email]',    :with => user.email
      fill_in 'session[password]', :with => user.password
      find('#sign_in_button').click
      page.should have_content("My Projects")

      visit root_path
      page.should have_content("Feedback")
      first("#feedback").click
      using_wait_time 2 do
        page.should have_content("max:1000")
      end
    end

  end

end
