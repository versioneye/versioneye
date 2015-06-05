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
      project[:name].should eql("spec_project_1")
      project.dependencies.first.save
      dep = project.dependencies.first 
      dep.version_label = '0.0'
      dep.version_requested = '0.0'
      dep.version_current = '0.1'
      dep.outdated = true 
      dep.save 

      project.update_attributes({user_id: user[:_id].to_s})
      project.reload
      ProjectUpdateService.update( project )
      project.dependencies.count.should eq(1)
      Project.all.count.should eq(1)
      Project.by_user(user).all.count eq(1)

      visit signin_path
      fill_in 'session[email]',    :with => user.email
      fill_in 'session[password]', :with => user.password
      find('#sign_in_button').click
      page.should have_content("My Projects")

      click_link "my_projects"
      page.should have_content(project[:name])
      click_link project[:name]
      page.should have_content("#{project[:name]}")
      
      page.should have_css(".btn-mute-version")
      page.should have_css(".mute-off")
      first(".btn-mute-version").click
      using_wait_time 2 do
        page.should have_css(".mute-on")
      end

      project.reload
      project.dependencies.first[:muted].should be_truthy


      first(".btn-mute-version").click
      using_wait_time 2 do
        page.should have_css(".mute-off")
      end

      project.reload
      project.dependencies.first[:muted].should be_falsey

    end
  end
end
