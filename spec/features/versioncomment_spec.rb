require 'spec_helper'

describe "Submit a Comment to specific package" do

  before :each do
    @user = UserFactory.create_new
    visit signin_path
    fill_in 'session[email]',    :with => @user.email
    fill_in 'session[password]', :with => @user.password
    find('#sign_in_button').click
    page.should have_content("My Projects")
  end

  describe "test the comment feature", :js => true do

    it "submits a comment" do
      product               = Product.new
      product.name          = "json_gobi"
      product.name_downcase = "json_gobi"
      product.prod_key      = "json_gobi"
      product.prod_type     = "RubyGem"
      product.language      = "Ruby"
      product.version       = "1.0"
      product.save
      version               = Version.new({:version => "1.0"})
      product.versions.push version

      version               = product.versions.first

      version.updated_at.should_not be_nil
      version.created_at.should_not be_nil

      visit "/ruby/json_gobi"

      fill_in 'versioncomment[comment]', :with => "This is a versioncomment XYZ123"
      click_button 'Save'
      page.should have_content("Comment saved!")

      visit "/ruby/json_gobi/1.0"
      page.should have_content("This is a versioncomment XYZ123")
    end

  end

end
