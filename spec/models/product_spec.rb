require 'spec_helper'

describe Product do
  
  before(:each) do
    @product = Product.new
  end
  
  after(:each) do 
    @product.remove
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

end