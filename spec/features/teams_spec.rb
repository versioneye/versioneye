require 'spec_helper'

describe "Teams" do

  before :each do
    Plan.create_defaults

    @paul = UserFactory.create_new 1
    expect( @paul.save ).to be_truthy

    @user = UserFactory.create_new 2
    expect( @user.save ).to be_truthy

    @maul = UserFactory.create_new 3
    expect( @maul.save ).to be_truthy
  end

  describe 'Team crud' do
    it "Creates a new team and adds a new member", js: true do

      # Login withe user, create new orga & team
      visit signin_path
      fill_in 'session[email]',    :with => @user.email
      fill_in 'session[password]', :with => @user.password
      find('#sign_in_button').click

      expect( Organisation.count ).to eq(0)

      visit organisations_path
      fill_in 'organisation[name]', :with => 'test_orga'
      fill_in 'organisation[company]', :with => 'test_orga'
      click_button 'Create Organisation'

      expect( Organisation.count ).to eq(1)
      expect( Team.count ).to eq(1) # Owner Team

      orga = Organisation.first
      visit organisation_teams_path( orga )
      fill_in 'teams[name]', :with => 'test_team'
      click_button 'Create New Team'

      expect( Team.count ).to eq(2)

      # Add new team member to new created team
      team = Team.where(:name => "test_team").first
      visit organisation_team_path(orga, team)

      fill_in 'username', :with => @paul.username
      click_button "Add Team Member"

      team = Team.where(:name => "test_team").first
      expect( team.members.count ).to eq(1)
      visit signout_path



      # Login with Paul and try to add new team member
      # That will fail because by default regular team
      # members are not allowed to add new team members.
      visit signin_path
      fill_in 'session[email]',    :with => @paul.email
      fill_in 'session[password]', :with => @paul.password
      find('#sign_in_button').click

      visit organisation_team_path(orga, team)

      fill_in 'username', :with => @user.username
      click_button "Add Team Member"

      page.should have_content("You are not authorized for this action.")
      team = Team.where(:name => "test_team").first
      expect( team.members.count ).to eq(1)

      visit organisation_teams_path( orga )
      fill_in 'teams[name]', :with => 'test2_team'
      click_button 'Create New Team'
      expect( Team.count ).to eq(2) # still 2 because user has no permission to create teams.

      visit signout_path



      # Login with user and check permission that regular team members can
      # add new team members to their team
      visit signin_path
      fill_in 'session[email]',    :with => @user.email
      fill_in 'session[password]', :with => @user.password
      find('#sign_in_button').click

      visit organisation_path(orga)
      check 'organisation[matanmtt]'
      click_button 'Update Organisation'
      visit signout_path



      # Login with Paul. Now he has permission to ad members to his team.
      visit signin_path
      fill_in 'session[email]',    :with => @paul.email
      fill_in 'session[password]', :with => @paul.password
      find('#sign_in_button').click

      visit organisation_team_path(orga, team)

      fill_in 'username', :with => @user.username
      click_button "Add Team Member"
      team = Team.where(:name => "test_team").first
      expect( team.members.count ).to eq(2)
      visit signout_path
    end

  end

end
