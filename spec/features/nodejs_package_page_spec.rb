require 'spec_helper'

describe "NodeJS path tester" do

  describe "testing nodejs paths on VersionEye", :js => true do

    it "visit nodejs language page with dot in lang" do
      prod1 = ProductFactory.create_for_npm('json', '1.0.0')
      prod1.save

      visit "/node.js"
      page.should have_content("json")
    end

    it "shows the nodejs page" do
      prod1 = ProductFactory.create_for_npm('json', '1.0.0')
      prod1.save

      visit "/nodejs/json/1.0.0"
      page.should have_content("json : 1.0.0")
    end

    it "shows the nodejs page with a dot in the language name" do
      prod1 = ProductFactory.create_for_npm('json', '1.0.0')
      prod1.save

      visit "/node.js/json/1.0.0"
      page.should have_content("json : 1.0.0")
    end

  end

end

