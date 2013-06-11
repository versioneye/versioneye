require 'spec_helper'

describe PomParser do

  describe "parse" do

    it "parse from https the file correctly" do
      parser = PomParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/pom.xml")
      project.should_not be_nil
    end

    it "parse the file correctly" do

      product_1 = ProductFactory.create_for_maven("junit", "junit", "4.4")
      product_1.save

      product_2 = ProductFactory.create_for_maven("commons-logging", "commons-logging", "1.1")
      product_2.save

      product_3 = ProductFactory.create_for_maven("commons-logging", "commons-logging-api", "1.1")
      product_3.save

      product_4 = ProductFactory.create_for_maven("log4j", "log4j", "1.2.15")
      product_4.save

      product_5 = ProductFactory.create_for_maven("javax.mail", "mail", "1.4")
      product_5.save

      product_6 = ProductFactory.create_for_maven("org.apache.commons", "commons-email", "1.4")
      product_6.save

      parser = PomParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/pom.xml")
      project.should_not be_nil

      dependency_01 = project.dependencies.first
      dependency_01.name.should eql("junit")
      dependency_01.version_requested.should eql("4.4")
      dependency_01.version_current.should eql("4.4")
      dependency_01.comperator.should eql("=")
      dependency_01.scope.should eql(Dependency::A_SCOPE_TEST)

      dependency_02 = project.dependencies[1]
      dependency_02.name.should eql("commons-logging")
      dependency_02.version_requested.should eql("1.1")
      dependency_02.version_current.should eql("1.1")
      dependency_02.comperator.should eql("=")
      dependency_02.scope.should eql("compile")

      dependency_03 = project.dependencies[2]
      dependency_03.name.should eql("commons-logging-api")
      dependency_03.version_requested.should eql("1.1")
      dependency_03.version_current.should eql("1.1")
      dependency_03.comperator.should eql("=")
      dependency_03.scope.should eql("compile")

      dependency_04 = project.dependencies[3]
      dependency_04.name.should eql("log4j")
      dependency_04.version_requested.should eql("1.2.15")
      dependency_04.version_current.should eql("1.2.15")
      dependency_04.comperator.should eql("=")
      dependency_04.scope.should eql("compile")

      dependency_05 = project.dependencies[4]
      dependency_05.name.should eql("mail")
      dependency_05.version_requested.should eql("1.4")
      dependency_05.version_current.should eql("1.4")
      dependency_05.comperator.should eql("=")
      dependency_05.scope.should eql("compile")

      dependency_06 = project.dependencies[5]
      dependency_06.name.should eql("commons-email")
      dependency_06.version_requested.should eql("1.2")
      dependency_06.version_current.should eql("1.4")
      dependency_06.comperator.should eql("=")
      dependency_06.scope.should eql("compile")

      product_1.remove
      product_2.remove
      product_3.remove
      product_4.remove
      product_5.remove
      product_6.remove
    end

  end

  describe "get_variable_value_from_pom" do

    it "returns val" do
      parser = PomParser.new
      properties = Hash.new
      parser.get_variable_value_from_pom(properties, "1.0").should eql("1.0")
    end

    it "returns still val" do
      properties = Hash.new
      properties["springVersion"] = "3.1"
      parser = PomParser.new
      parser.get_variable_value_from_pom(properties, "1.0").should eql("1.0")
    end

    it "returns value from the properties" do
      properties = Hash.new
      properties["springversion"] = "3.1"
      parser = PomParser.new
      parser.get_variable_value_from_pom(properties, "${springVersion}").should eql("3.1")
    end

    it "returns 3.1 because of downcase!" do
      properties = Hash.new
      properties["springversion"] = "3.1"
      parser = PomParser.new
      parser.get_variable_value_from_pom(properties, "${springVERSION}").should eql("3.1")
    end

    it "returns val because properties is empty" do
      parser = PomParser.new
      properties = Hash.new
      parser.get_variable_value_from_pom(properties, "${springVersion}").should eql("${springVersion}")
    end

  end

end
