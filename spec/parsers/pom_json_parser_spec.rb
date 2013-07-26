require 'spec_helper'

describe PomParser do

  describe "parse" do

    it "parse from https the file correctly" do
      parser = PomParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/pom.json")
      project.should_not be_nil
    end

    it "parse the file correctly" do

      product_1 = ProductFactory.create_for_maven("net.sourceforge.htmlunit", "htmlunit", "2.12")
      product_1.save

      product_2 = ProductFactory.create_for_maven("net.sourceforge.htmlcleaner", "htmlcleaner", "2.4")
      product_2.save

      parser = PomJsonParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/pom.json")
      project.should_not be_nil

      dependency_01 = project.dependencies.first
      dependency_01.name.should eql("net.sourceforge.htmlunit:htmlunit")
      dependency_01.group_id.should eql("net.sourceforge.htmlunit")
      dependency_01.artifact_id.should eql("htmlunit")
      dependency_01.version_requested.should eql("2.12")
      dependency_01.version_current.should eql("2.12")
      dependency_01.comperator.should eql("=")

      dependency_02 = project.dependencies[1]
      dependency_02.name.should eql("net.sourceforge.htmlcleaner:htmlcleaner")
      dependency_02.group_id.should eql("net.sourceforge.htmlcleaner")
      dependency_02.artifact_id.should eql("htmlcleaner")
      dependency_02.version_requested.should eql("2.4")
      dependency_02.version_current.should eql("2.4")
      dependency_02.comperator.should eql("=")

    end

  end

end
