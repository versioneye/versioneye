require 'spec_helper'

describe "Computer Language Filter" do

  before :all do
    Product.destroy_all
    prod1 = ProductFactory.create_for_maven("junit", "json-test", "1.0.0")
    prod2 = ProductFactory.create_for_maven("json", "jsonJ", "1.0.0")
    prod3 = ProductFactory.create_for_gemfile("json2", "1.1.1")
    prod4 = ProductFactory.create_for_gemfile("jsonG", "2.1.1")
    prod5 = ProductFactory.create_for_composer("jsonC", "3.0.0")
    prod1.save
    prod2.save
    prod3.save
    prod4.save
    prod5.save
    EsProduct.reset
    EsProduct.index_all
  end

  describe "the computer language filter", :js => true do

    it "uses the language filter without errors" do
      visit root_path

      fill_in 'q', :with => "json*"
      click_button "Search"

      page.should have_content("json-test")
      page.should have_content("jsonJ")
      page.should have_content("json2")
      page.should have_content("jsonG")
      page.should have_content("jsonC")

      visit root_path
      fill_in 'q', :with => "json*"
      find(:xpath, '//div[contains(@class, "icon_java_small_container")]' ).click
      click_button  "Search"

      page.should     have_content("json-test")
      page.should     have_content("jsonJ")
      page.should_not have_content("json2")
      page.should_not have_content("jsonG")
      page.should_not have_content("jsonC")

      find(:xpath, '//label[contains(@for, "Ruby")]' ).click
      click_button "Search"

      page.should     have_content("json-test")
      page.should     have_content("jsonJ")
      page.should     have_content("json2")
      page.should     have_content("jsonG")
      page.should_not have_content("jsonC")

      find(:xpath, '//label[contains(@id, "label_Java__")]' ).click
      find(:xpath, '//label[contains(@for, "Ruby")]' ).click
      find(:xpath, '//label[contains(@for, "PHP")]' ).click
      click_button "Search"

      page.should_not have_content("json-test")
      page.should_not have_content("jsonJ")
      page.should_not have_content("json2")
      page.should_not have_content("jsonG")
      page.should     have_content("jsonC")
    end

  end

end
