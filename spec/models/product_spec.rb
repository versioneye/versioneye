require 'spec_helper'

describe Product do
  
  before(:each) do
    @product = Product.new
  end
  
  after(:each) do 
    @product.remove
  end
  
  describe "versions_empty?" do
    
    it "returns true" do 
      @product.versions_empty?.should be_true
    end
    
    it "returns false" do 
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      @product.versions_empty?.should be_false
    end
    
    it "returns false" do 
      @product.versions = Array.new
      @product.name = "test"
      @product.prod_key = "gasgagasgj8623_junit/junit23"
      @product.rate = 50
      @product.save
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      prod = Product.find_by_key("gasgagasgj8623_junit/junit23")
      prod.versions_empty?.should be_false
    end
    
  end
  
  describe "find_by_name" do
    
    it "returns an empty list. Search term is not in the DB" do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.rate = 50
      @product.save
      results = Product.find_by_name( "sgj8623agajklnb8738gas" )
      results.should_not be_nil
      results.size.should eq(0)
    end
    
    it "returns an empty list. Search term is an empty string" do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.rate = 50
      @product.save
      results = Product.find_by_name( "" )
      results.should_not be_nil
      results.size.should eq(0)
    end
    
    it "returns an empty list. Search term is nil" do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.rate = 50
      @product.save
      results = Product.find_by_name( nil )
      results.should_not be_nil
      results.size.should eq(0)
    end
    
    it "returns the searhced product. Simple case. Exact macht!" do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.rate = 50
      @product.save
      results = Product.find_by_name( name )
      results.should_not be_nil
      results.size.should eq(1)
    end
    
    it "returns the searhced product. Upper Case. Exact macht with caseinsensitive!" do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.rate = 50
      @product.save
      results = Product.find_by_name( "JUNITggasGagasgj8623" )
      results.should_not be_nil
      results.size.should eq(1)
    end
    
    it "returns the searhced product. Part of the Name - first digits." do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.rate = 50
      @product.save
      results = Product.find_by_name( "junitggasg" )
      results.should_not be_nil
      results.size.should eq(1)
    end
    
    it "returns the searhced product. Part of the Name - last digits." do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.rate = 50
      @product.save
      results = Product.find_by_name( "sgj8623" )
      results.should_not be_nil
      results.size.should eq(1)
    end
    
    it "returns the searhced product. Part of the Name - middle digits." do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.rate = 50
      @product.save
      results = Product.find_by_name( "tggasgagasgj86" )
      results.should_not be_nil
      results.size.should eq(1)
    end
    
  end
  
  describe "find_by_key" do
    
    it "return nil. Because input is nil" do 
      result = Product.find_by_key(nil)
      result.should be_nil
    end
    
    it "return nil. Because input is empty" do 
      result = Product.find_by_key("  ")
      result.should be_nil
    end
    
    it "return nil. Because there are no results." do 
      result = Product.find_by_key("gasflasjgfaskjgas848asjgfasgfasgf")
      result.should be_nil
    end
    
  end
  
  describe "get_newest_version_by_natural_order" do 
    
    it "returns the newest version correct." do
      @product.versions = Array.new
      ver = 1
      5.times{
        version = Version.new
        version.version = ver.to_s
        ver += 1
        @product.versions.push(version)
      }
      version = @product.get_newest_version_by_natural_order
      version.should eql("5")
    end
    
    it "returns the newest version correct. With decimal numbers." do
      @product.versions = Array.new
      ver = 1
      5.times{
        version = Version.new
        version.version = "1." + ver.to_s
        ver += 1
        @product.versions.push(version)
      }
      version = @product.get_newest_version_by_natural_order
      version.should eql("1.5")
    end
    
    it "returns the newest version correct. With long numbers." do
      @product.versions = Array.new
      
      version1 = Version.new
      version1.version = "1.2.2"
      @product.versions.push(version1)
      
      version2 = Version.new
      version2.version = "1.2.29"
      @product.versions.push(version2)
      
      version3 = Version.new
      version3.version = "1.3"
      @product.versions.push(version3)
      
      version = @product.get_newest_version_by_natural_order
      version.should eql("1.3")
    end
    
    it "returns the newest version correct. With long numbers. Wariant 2." do
      @product.versions = Array.new
      
      version1 = Version.new
      version1.version = "1.22"
      @product.versions.push(version1)
      
      version2 = Version.new
      version2.version = "1.229"
      @product.versions.push(version2)
      
      version3 = Version.new
      version3.version = "1.30"
      @product.versions.push(version3)
      
      version = @product.get_newest_version_by_natural_order
      version.should eql("1.229")
    end
    
  end

end