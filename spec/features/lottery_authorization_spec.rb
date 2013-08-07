require 'spec_helper'

describe 'lottery authorization' do
  let(:existing_user){FactoryGirl.create(:default_user)}
  
  describe "login with existing user credentials", :js => true do 
    it "should login with correct credentials and redirect to lottery page" do
      visit '/lottery'
      current_path.should == lottery_path
    
      find('#collapse2_link').click #opens accordion
      fill_in 'session[email]',    with: existing_user[:email]
      fill_in 'session[password]', with: 'password'
      click_button 'Sign in'

      should_not have_css(".flash-container")
      current_path.should == lucky_lottery_path

    end
  end

  describe "signup as new user", :js => true do 
    it "should signup with user data and redirect to lottery page" do
      User.all.delete_all
      visit '/lottery'
      current_path.should == lottery_path

      fill_in 'user[email]', with: 'spec_demo_1@spec.com'
      fill_in 'user[fullname]', with: 'Spec user'
      fill_in 'user[password]', with: '12345'
      check('user[terms]')

      find('#btn-signup').click

      current_path.should == lucky_lottery_path
      should_not have_css(".flash_container")
    end
  end
end
