require 'spec_helper'

describe RequirementsParser do

  describe "parse" do

    it "parse from https the file correctly" do
      parser = RequirementsParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/requirements.txt")
      project.should_not be_nil
    end

    it "parse from http the file correctly" do
      name = "South"
      product = Product.new
      product.name = name
      product.name_downcase = name
      product.prod_key = "pip/South"
      product.version = "1.0.0"
      product.save
      version1 = Version.new
      version1.version = "0.7.3"
      product.versions.push(version1)
      version2 = Version.new
      version2.version = "0.7.2"
      product.versions.push(version2)
      version3 = Version.new
      version3.version = "1.0.0"
      product.versions.push(version3)
      product.save

      name2 = "amqplib"
      product2 = Product.new
      product2.name = name2
      product2.name_downcase = name2
      product2.prod_key = "pip/amqplib"
      product2.version = "2.0.0"
      product2.save
      version2_1 = Version.new
      version2_1.version = "1.0.2"
      product2.versions.push(version2_1)
      version2_2 = Version.new
      version2_2.version = "1.0.0"
      product2.versions.push(version2_2)
      version2_3 = Version.new
      version2_3.version = "2.0.0"
      product2.versions.push(version2_3)
      product2.save

      name3 = "Django"
      product3 = Product.new
      product3.name = name3
      product3.name_downcase = "django"
      product3.prod_key = "pip/django"
      product3.version = "1.4.0"
      product3.save
      version3_1 = Version.new
      version3_1.version = "1.3.1"
      product3.versions.push(version3_1)
      version3_2 = Version.new
      version3_2.version = "1.3.5"
      product3.versions.push(version3_2)
      version3_3 = Version.new
      version3_3.version = "1.4.0"
      product3.versions.push(version3_3)
      product3.save

      name4 = "PIL"
      product4 = Product.new
      product4.name = name4
      product4.name_downcase = name4
      product4.prod_key = "pip/PIL"
      product4.version = "1.1.7"
      product4.save
      version4_1 = Version.new
      version4_1.version = "1.1.7"
      product4.versions.push(version4_1)
      product4.save

      name5 = "jsmin"
      product5 = Product.new
      product5.name = name5
      product5.name_downcase = name5
      product5.prod_key = "pip/jsmin"
      product5.version = "1.1.7"
      product5.save
      version5_1 = Version.new
      version5_1.version = "1.1.7"
      product5.versions.push(version5_1)
      product5.save

      parser = RequirementsParser.new
      project = parser.parse("http://s3.amazonaws.com/veye_test_env/requirements.txt")
      project.should_not be_nil
      project.dependencies.size.should eql(22)

      dep_01 = project.dependencies.first
      dep_01.name.should eql("Django")
      dep_01.version_requested.should eql("1.3.1")
      dep_01.version_current.should eql("1.4.0")
      dep_01.comperator.should eql("==")

      dep_02 = project.dependencies[1]
      dep_02.name.should eql("PIL")
      dep_02.version_requested.should eql("1.1.7")
      dep_02.version_current.should eql("1.1.7")
      dep_02.comperator.should eql("==")

      dep_03 = project.dependencies[2]
      dep_03.name.should eql("South")
      dep_03.version_requested.should eql("0.7.3")
      dep_03.version_current.should eql("1.0.0")
      dep_03.comperator.should eql("<=")

      dep_04 = project.dependencies[3]
      dep_04.name.should eql("amqplib")
      dep_04.version_requested.should eql("2.0.0")
      dep_04.version_current.should eql("2.0.0")
      dep_04.comperator.should eql(">=")

      dep_05 = project.dependencies[20]
      dep_05.name.should eql("jsmin")
      dep_05.version_requested.should eql("1.1.7")
      dep_05.version_current.should eql("1.1.7")
      dep_05.comperator.should eql(nil)

      project.dependencies.last.name.should eql("emencia.django.newsletter")
    end

  end

  describe "extract_comparator" do

    it "returns the right splitt ==" do
      parser = RequirementsParser.new
      parser.extract_comparator("django==1.0").should eql("==")
    end

    it "returns the right splitt <" do
      parser = RequirementsParser.new
      parser.extract_comparator("django<1.0").should eql("<")
    end

    it "returns the right splitt <=" do
      parser = RequirementsParser.new
      parser.extract_comparator("django<=1.0").should eql("<=")
    end

    it "returns the right splitt >" do
      parser = RequirementsParser.new
      parser.extract_comparator("django>1.0").should eql(">")
    end

    it "returns the right splitt >=" do
      parser = RequirementsParser.new
      parser.extract_comparator("django>=1.0").should eql(">=")
    end

    it "returns the right splitt !=" do
      parser = RequirementsParser.new
      parser.extract_comparator("django!=1.0").should eql("!=")
    end

    it "returns nil" do
      parser = RequirementsParser.new
      parser.extract_comparator("django").should be_nil
    end

  end

end
