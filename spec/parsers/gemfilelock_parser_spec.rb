require 'spec_helper'

describe GemfilelockParser do
  describe "parse" do
    before :each do
      @testfile_url = "https://s3.amazonaws.com/veye_test_env/Gemfile.lock"
      @parser = GemfilelockParser.new

      @product1 = ProductFactory.create_for_gemfile("daemons", "1.1.4")
      @product1.versions.push Version.new({version: "1.0.9"})
      @product1.versions.push Version.new({version: "1.1.0"})
      @product1.save
       
      @product2 = ProductFactory.create_for_gemfile("eventmachine", "0.12.10")
      @product2.versions.push Version.new({version: "0.12.6"})
      @product2.save
  
      @product3 = ProductFactory.create_for_gemfile("rack", "1.4.1")
      @product3.versions.push Version.new({version: "1.4.1"})
      @product3.versions.push Version.new({version: "1.3"})
      @product3.versions.push Version.new({version: "1.3.6"})
      @product3.versions.push Version.new({version: "1.3.9"})
      @product3.save

      @product4 = ProductFactory.create_for_gemfile "rack-protection", "1.2.0"
      @product4.save

      @product5 = ProductFactory.create_for_gemfile "sinatra", "1.3.3"
      @product5.save

      @product6 = ProductFactory.create_for_gemfile "tilt", "1.3.3"
      @product6.save

      @product7 = ProductFactory.create_for_gemfile "thin", "1.3.1"
      @product7.save

    end

    after :each do
      Product.all.delete_all
    end

    it "reads file correctly from web" do 
      project = @parser.parse @testfile_url
      project.should_not be_nil
    end

    it "parses test file correctly" do
      project = @parser.parse @testfile_url
      
      project.should_not be_nil
      project.dependencies.count.should eql(7)

      dep1 = project.dependencies.first
      dep1.name.should eql(@product1.name)
      dep1.version_requested.should eql(@product1.version)

      dep2 = project.dependencies[1]
      dep2.name.should eql(@product2.name)
      dep2.version_requested.should eql(@product2.version)

      dep3 = project.dependencies[2]
      dep3.name.should eql(@product3.name)
      dep3.version_requested.should eql(@product3.version)

      dep4 = project.dependencies[3]
      dep4.name.should eql(@product4.name)
      dep4.version_requested.should eql(@product4.version)

      dep5 = project.dependencies[4]
      dep5.name.should eql(@product5.name)
      dep5.version_requested.should eql(@product5.version)

      dep6 = project.dependencies[5]
      dep6.name.should eql(@product6.name)
      dep6.version_requested.should eql(@product6.version)

      dep7 = project.dependencies[6]
      dep7.name.should eql(@product7.name)
      dep7.version_requested.should eql(@product7.version)

    end
  end
end
