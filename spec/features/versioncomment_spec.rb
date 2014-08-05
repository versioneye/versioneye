require 'spec_helper'

describe "Submit a Comment to specific package" do

  let(:product){FactoryGirl.build(:product,
                                   name:           "json_gobi",
                                   name_downcase:  "json_gobi",
                                   prod_key:       "json_gobi",
                                   prod_type:      "RubyGem",
                                   language:       "Ruby"
                                )}
  before :each do
    Rails.cache.clear
    LanguageService.cache.delete "distinct_languages"

    @user = UserFactory.create_new
    visit signin_path
    fill_in 'session[email]',    :with => @user.email
    fill_in 'session[password]', :with => @user.password
    find('#sign_in_button').click
    page.should have_content("My Projects")
  end

  describe "test the comment feature", :js => true do

    it "submits a comment" do
      product.version = "1.0"
      product.save
      product.versions << Version.new({:version => "1.0"})

      version = product.versions.first
      version.updated_at.should_not be_nil
      version.created_at.should_not be_nil

      visit "/ruby/json_gobi/1.0"

      fill_in 'versioncomment[comment]', :with => "This is a versioncomment XYZ123"
      click_button 'Save'
      page.should have_content("Comment saved!")

      visit "/ruby/json_gobi/1.0"
      page.should have_content("This is a versioncomment XYZ123")
    end

  end

end
