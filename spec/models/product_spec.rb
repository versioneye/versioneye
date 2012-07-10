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
      @product.save
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      prod = Product.find_by_key("gasgagasgj8623_junit/junit23")
      prod.versions_empty?.should be_false
    end
    
  end
  
  describe "find_by" do
    
    it "returns an empty list. Search term is not in the DB" do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.name_downcase = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.save
      results = Product.find_by( "sgj8623agajklnb8738gas", nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(0)
    end
    
    it "returns an empty list. Search term is an empty string" do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.name_downcase = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.save
      results = Product.find_by( "", nil, nil, nil, 300 )
      results.should_not be_nil
      results.size.should eq(0)
    end
    
    it "returns an empty list. Search term is nil" do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.name_downcase = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.save
      results = Product.find_by( nil, nil, nil, nil, 300 )
      results.should_not be_nil
      results.size.should eq(0)
    end
    
    it "returns the searhced product. Simple case. Exact macht!" do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.name_downcase = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.save
      results = Product.find_by( name, nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(1)
    end
    
    it "returns the searhced product. Upper Case. Exact macht with caseinsensitive!" do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.name_downcase = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.save
      results = Product.find_by( name, nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(1)
    end
    
    it "returns the searhced product. Part of the Name - first digits." do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.name_downcase = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.save
      results = Product.find_by( "junitggasg", nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(1)
    end
    
    it "returns the searhced product. Part of the Name - last digits." do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.name_downcase = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.save
      results = Product.find_by( "sgj8623", nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(1)
    end

    it "returns the searhced product. Part of the Name - last digits." do
      name = "hiberante-core"
      @product.name = name
      @product.name_downcase = name
      @product.prod_key = "org/hibernate-core"
      @product.save
      results = Product.find_by( "hiberante-core", nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(1)
    end
    
    it "returns the searhced product. Part of the Name - middle digits." do
      name = "junitggasgagasgj8623"
      @product.name = name
      @product.name_downcase = name
      @product.prod_key = "gasgagasgj8623_junit/junit"
      @product.save
      results = Product.find_by( "tggasgagasgj86", nil, nil, nil, 300 )
      results.should_not be_nil
      results.size.should eq(1)
    end

    it "returns the searhced product because searched_name is in description" do
      @product.name = "asgfasfgasgasfgs"
      @product.name_downcase = "asgfasfgasgasfgs"
      @product.prod_key = "gasgagasgj8623_junit/junitagasfgas"
      @product.description = "this is BuBuBo. OK?"
      @product.save
      results = Product.find_by( "BuBuBo", nil, nil, nil, 300 )
      results.should_not be_nil
      results.size.should eq(1)
    end

    it "returns the searhced product because searched_name is in description_manual" do
      @product.name = "asgfasfgasgasfgs"
      @product.name_downcase = "asgfasfgasgasfgs"
      @product.prod_key = "gasgagasgj8623_junit/junitagasfgas"
      @product.description_manual = "this is BuBuBoHapo gasgfs"
      @product.save
      results = Product.find_by( "BuBuBoHapo", nil, nil, nil, 300 )
      results.should_not be_nil
      results.size.should eq(1)
    end

    it "returns searhced products. Combination of start and simple" do
      name = "start_not_apple"
      @product.name = name
      @product.name_downcase = name
      @product.prod_key = "apple_bike_pie/unit"
      @product.save

      product = Product.new
      product.versions = Array.new
      product.name = "apple_start_with"
      product.name_downcase = "apple_start_with"
      product.prod_key = "apple_bike_pie12/unit"
      product.save

      results = Product.find_by( "apple", nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(2)

      product.remove
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
  
  describe "get_links" do
    
    it "returns an empty array" do
      @product.get_links.size.should eq(0)
    end

    it "returns one link" do
      link = Versionlink.new
      link.prod_key = @product.prod_key
      link.link = "http://link.de"
      link.name = "Name"
      link.save
      @product.get_links.size.should eq(1)
      link.remove
    end

    it "returns an empty array" do
      link = Versionlink.new
      link.prod_key = @product.prod_key
      link.link = "http://link.de"
      link.version_id = "nope"
      link.name = "Name"
      link.save
      @product.get_links.size.should eq(0)
      link.remove
    end

    it "returns 1 link" do
      link = Versionlink.new
      link.prod_key = @product.prod_key
      link.link = "http://link.de"
      link.version_id = "1.1"
      link.name = "Name"
      link.save
      @product.version = "1.1"
      @product.get_version_links.size.should eq(1)
      link.remove
    end
    
  end
  
  describe "find_by_group_and_artifact" do
    
    it "returns nil because of wrong parameters" do
      Product.find_by_group_and_artifact("bullshit", "bingo").should be_nil
    end
    
    it "returns the correct product" do
      group = "junit56"
      artifact = "junit23"
      @product.versions = Array.new
      @product.name = "test"
      @product.prod_key = "#{group}/#{artifact}"
      @product.group_id = group
      @product.artifact_id = artifact
      @product.save
      version = Version.new
      prod = Product.find_by_group_and_artifact(group, artifact)
      prod.should_not be_nil
      prod.group_id.should eql(group)
      prod.artifact_id.should eql(artifact)
    end
    
  end
  
  describe "get_newest" do
    
    it "returns 1.0 from 1.0 and 0.1" do
      Naturalsorter::Sorter.get_newest_version("1.0", "0.1").should eql("1.0")
    end
    it "returns 1.10 from 1.10 and 1.9" do
      Naturalsorter::Sorter.get_newest_version("1.10", "1.9").should eql("1.10")
    end
    
  end
  
  describe "wouldbenewest" do
    
    it "returns false" do
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      @product.wouldbenewest?("1.0").should be_false 
    end
    it "returns false for smaller version" do
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      @product.wouldbenewest?("0.9").should be_false 
    end
    it "returns true for bigger version" do
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      @product.wouldbenewest?("1.1").should be_true
    end
    it "returns true for much bigger version" do
      version = Version.new
      version.version = "1.9"
      @product.versions.push(version)
      @product.wouldbenewest?("1.10").should be_true
    end
    
  end

end