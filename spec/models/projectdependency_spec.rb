require 'spec_helper'

describe Projectdependency do
  
  before(:each) do 
    @product = Product.new
    @product.name = "gomezify"
    @product.prod_key = "gomezify"
    @product.versions = Array.new
    version = Version.new
    version.version = "1.0"
    @product.versions.push(version)
    @product.version = "1.0"
    @product.save
  end

  after(:each) do 
    @product.remove
  end

  describe "outdated?" do 
    
    it "is up to date" do       
      dep = Projectdependency.new
      dep.prod_key = "gomezify"
      dep.version_requested = "1.0"
      dep.outdated?.should be_false
    end

    it "is outdated" do       
      dep = Projectdependency.new
      dep.prod_key = "gomezify"
      dep.version_requested = "0.9"
      dep.outdated?.should be_true
    end

    it "is up to date" do       
      dep = Projectdependency.new
      dep.prod_key = "gomezify"
      dep.version_requested = "1.9"
      dep.outdated?.should be_false
    end

    it "is up to date" do
      prod_key = "symfony/locale_de"
      product = ProductFactory.create_for_composer(prod_key, "2.2.x-dev")
      version_01 = Version.new 
      version_01.version = "2.2.1"
      product.versions.push( version_01 )
      product.save
    
      dep = Projectdependency.new
      dep.prod_key = product.prod_key
      dep.version_requested = "2.2.x-dep"
      dev.outdated?.should be_false
      dep.version_current.should eql("2.2.x-dev")

      product.remove
    end

  end
  
end