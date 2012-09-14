require 'spec_helper'

describe Dependency do
  
  describe "gem_version" do 
    
    it "returns valid value" do 
  		dependency = Dependency.new
  		dependency.version = "1.0"
  		dependency.gem_version().should eql("1.0")
    end

    it "returns valid value" do
  		dependency = Dependency.new
  		dependency.version = "= 1.0"
  		dependency.gem_version().should eql("1.0")
  	end

  	it "returns valid value" do
  		dependency = Dependency.new
  		dependency.version = " =  1.0"
  		dependency.gem_version().should eql("1.0")
  	end

  end

  describe "gem_version_abs" do 
    
    it "returns valid value" do 
    	product = Product.new
      product.versions = Array.new
      product.name = "test"
      product.prod_key = "gasgagasgj8623_jun44444it/juasgnit23afsg"

      version = Version.new
      version.version = "1.0"
      product.versions.push(version)

      version = Version.new
      version.version = "1.1"
      product.versions.push(version)

      version = Version.new
      version.version = "1.2"
      product.versions.push(version)

      version = Version.new
      version.version = "2.0"
      product.versions.push(version)
      product.save

      dependency = Dependency.new
      dependency.version = "~> 1.0"
      dependency.dep_prod_key = product.prod_key
      dependency.gem_version_abs().should eql("1.2")
      
      product.remove
    end

    it "returns valid value" do 
    	product = Product.new
    	product.versions = Array.new
      product.name = "test"
      product.prod_key = "huj_buuuuu"

      version = Version.new
      version.version = "1.2"
      product.versions.push(version)

      version = Version.new
      version.version = "2.0"
      product.versions.push(version)
      	
      version = Version.new
      version.version = "2.2.1"
      product.versions.push(version)

      version = Version.new
      version.version = "2.2.2"
      product.versions.push(version)

      version = Version.new
      version.version = "2.2.9"
      product.versions.push(version)

      version = Version.new
      version.version = "2.3"
      product.versions.push(version)

      product.save

      dependency = Dependency.new
      dependency.version = "~> 2.2"
      dependency.dep_prod_key = product.prod_key
      dependency.gem_version_abs().should eql("2.2.9")

      dependency.version = "~> 2.0"
      dependency.dep_prod_key = product.prod_key
      dependency.gem_version_abs().should eql("2.3")

      product.remove
    end

  end
  
end