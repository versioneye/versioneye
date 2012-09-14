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

  describe "is_outdated?" do 
    
    it "is up to date" do       
      dep = Projectdependency.new
      dep.prod_key = "gomezify"
      dep.version_requested = "1.0"
      dep.is_outdated?.should be_false
    end

    it "is up to date" do       
      dep = Projectdependency.new
      dep.prod_key = "gomezify"
      dep.version_requested = "0.9"
      dep.is_outdated?.should be_true
    end

    it "is up to date" do       
      dep = Projectdependency.new
      dep.prod_key = "gomezify"
      dep.version_requested = "1.9"
      dep.is_outdated?.should be_false
    end

  end
  
end