require 'spec_helper'

describe "Submit a Comment to specific package" do

  before :all do
    @user = UserFactory.create_new
  end

  before :each do
    visit signin_path
    fill_in 'session[email]',    :with => @user.email
    fill_in 'session[password]', :with => @user.password
    find('#sign_in_button').click
    page.should have_content("My Projects")
  end

  describe "test the comment feature", :js => true do

    it "submits a comment" do
      product               = Product.new
      product.versions      = Array.new
      product.name          = "json_gobi"
      product.name_downcase = "json_gobi"
      product.prod_key      = "json_gobi"
      product.prod_type     = "RubyGem"
      product.language      = "Ruby"
      product.version       = "1.0"
      version               = Version.new
      version.version       = "1.0"
      product.versions.push(version)
      product.save

      visit "/ruby/json_gobi"

      fill_in 'versioncomment[comment]', :with => "This is a versioncomment XYZ123"
      click_button 'Save'
      page.should have_content("Comment saved!")

      visit "/ruby/json_gobi/1.0"
      page.should have_content("This is a versioncomment XYZ123")
    end

  end

end
