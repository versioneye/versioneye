require 'spec_helper'

describe "Mute project dependency", :js => true do

  let(:user){ FactoryGirl.create(:default_user)}
  let(:product){FactoryGirl.create(:product,
    prod_key: "spec_product1",
    language: "Ruby"
  )}
  let(:project){FactoryGirl.create(:project_with_deps, deps_count: 1)}


  context "mute project dependency" do
    it "mutes&unmutes project dependency when authorized user clicks on mute-button" do

      Plan.create_defaults
      orga = OrganisationService.create_new_for( user )
      expect( orga.save ).to be_truthy

      project.organisation = orga
      expect(project.save).to be_truthy

      project[:name].should eql("spec_project_1")
      project.dependencies.first.save
      dep = project.dependencies.first
      dep.version_label = '0.0'
      dep.version_requested = '0.0'
      dep.version_current = '0.1'
      dep.outdated = true
      expect( dep.save ).to be_truthy

      expect( user ).to_not be_nil
      expect( user.ids ).to_not be_nil

      project.update_attributes({user_id: user[:_id].to_s})
      project.reload
      ProjectUpdateService.update( project )
      project.dependencies.count.should eq(1)
      Project.all.count.should eq(1)
      expect( Project.by_user(user).count ).to eq(1)

      visit signin_path
      fill_in 'session[email]',    :with => user.email
      fill_in 'session[password]', :with => user.password
      find('#sign_in_button').click
      page.should have_content("Projects")

      OrganisationService.transfer project, orga

      visit projects_organisation_path(orga.name)
      page.should have_content(project[:name])
      click_link project[:name]
      page.should have_content("#{project[:name]}")

      page.should have_css(".btn-mute-version")
      page.should have_css(".mute-off")
      first(".btn-mute-version").click

      # Click mute button in dialog window
      find('#mute_button').click

      using_wait_time 4 do
        page.should have_css(".mute-on")
      end

      project.reload
      project.dependencies.first[:muted].should be_truthy

      visit "/user/projects/#{project.ids}"
      first(".btn-mute-version").click
      using_wait_time 5 do
        page.should have_css(".mute-off")
      end

      project.reload
      project.dependencies.first[:muted].should be_falsey
    end
  end
end
