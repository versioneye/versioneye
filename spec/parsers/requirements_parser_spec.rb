require 'spec_helper'

describe RequirementsParser do

  describe "parse" do

    it "parse from https the file correctly" do
      parser = RequirementsParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/requirements.txt")
      project.should_not be_nil
    end

    it "parse from http the file correctly" do

      product1  = create_product('South'  , 'South'  , '1.0.0', ['0.7.3', '0.7.2', '1.0.0' ])
      product2  = create_product('amqplib', 'amqplib', '2.0.0', ['1.0.2', '1.0.0', '2.0.0' ])
      product3  = create_product('Django' , 'django' , '1.4.0', ['1.3.1', '1.3.5', '1.4.0' ])
      product4  = create_product('PIL'    , 'PIL'    , '1.1.7' )
      product5  = create_product('jsmin'  , 'jsmin'  , '1.1.7' )

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

  def create_product(name, prod_key, version, versions = nil )
    product = Product.new({ :language => Product::A_LANGUAGE_PYTHON, :prod_type => Project::A_TYPE_PIP })
    product.name = name
    product.prod_key = prod_key
    product.version = version
    product.add_version( version )
    product.save

    return product if !versions

    versions.each do |ver|
      product.add_version( ver )
    end
    product.save

    product
  end

end
