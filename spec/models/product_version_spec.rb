require 'spec_helper'

describe Product do
  
  before(:each) do
    @product = Product.new
  end
  
  after(:each) do 
    @product.remove
  end

  describe "update_version_data" do 

    it "returns the one" do 
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      @product.update_version_data
      @product.version.should eql("1.0")
    end

    it "returns the highest stable" do 
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      
      version2 = Version.new
      version2.version = "1.1"
      @product.versions.push(version2)

      version3 = Version.new
      version3.version = "1.2-dev"
      @product.versions.push(version3)

      @product.update_version_data
      @product.version.should eql("1.1")
    end

  end
  
  describe "get_greater_than" do
    
    it "returns the highest value" do
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      version2 = Version.new
      version2.version = "1.1"
      @product.versions.push(version2)
      version3 = Version.new
      version3.version = "1.2"
      @product.versions.push(version3)
      ver = @product.greater_than("1.1")
      ver.version.should eql("1.2")
    end
    
  end

  describe "greater_than_or_equal" do
    
    it "returns the highest value" do
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      version2 = Version.new
      version2.version = "1.1"
      @product.versions.push(version2)
      version3 = Version.new
      version3.version = "1.2"
      @product.versions.push(version3)
      ver = @product.greater_than_or_equal("1.1")
      ver.version.should eql("1.2")
    end

    it "returns the highest value" do
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      version2 = Version.new
      version2.version = "1.1"
      @product.versions.push(version2)
      ver = @product.greater_than_or_equal("1.1")
      ver.version.should eql("1.1")
    end
    
  end

  describe "get_smaller_than_or_equal" do
    
    it "returns the highest value" do
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      version2 = Version.new
      version2.version = "1.1"
      @product.versions.push(version2)
      version3 = Version.new
      version3.version = "1.2"
      @product.versions.push(version3)
      ver = @product.smaller_than_or_equal("1.1")
      ver.version.should eql("1.1")
    end

    it "returns the highest value" do
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      ver = @product.smaller_than_or_equal("1.1")
      ver.version.should eql("1.0")
    end
    
  end

  describe "smaller_than" do
    
    it "returns the highest value" do
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      version2 = Version.new
      version2.version = "1.1"
      @product.versions.push(version2)
      version3 = Version.new
      version3.version = "1.2"
      @product.versions.push(version3)
      ver = @product.smaller_than("1.1")
      ver.version.should eql("1.0")
    end

    it "returns the highest value" do
      @product.versions = Array.new
      version = Version.new
      version.version = "2.2.2"
      @product.versions.push(version)
      version2 = Version.new
      version2.version = "2.2.3"
      @product.versions.push(version2)
      version3 = Version.new
      version3.version = "2.3.0"
      @product.versions.push(version3)
      ver = @product.smaller_than("2.4-dev")
      ver.version.should eql("2.3.0")
    end
    
  end

  describe "get_version_range" do 

    it "returns the right range" do 
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      version2 = Version.new
      version2.version = "1.1"
      @product.versions.push(version2)
      version3 = Version.new
      version3.version = "1.2"
      @product.versions.push(version3)
      version4 = Version.new
      version4.version = "1.3"
      @product.versions.push(version4)
      version5 = Version.new
      version5.version = "1.4"
      @product.versions.push(version5)

      range = @product.version_range("1.1", "1.3")
      range.count.should eql(3)
      range.first.version.should eql("1.1")
      range.last.version.should eql("1.3")
    end

  end

  describe "get_tilde_newest" do 

    # TODO make it work with 1.345
    it "returns the right value" do 
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      version2 = Version.new
      version2.version = "1.1"
      @product.versions.push(version2)
      version3 = Version.new
      version3.version = "1.2"
      @product.versions.push(version3)
      version4 = Version.new
      version4.version = "1.3"
      @product.versions.push(version4)
      version5 = Version.new
      version5.version = "2.0"
      @product.versions.push(version5)

      tilde_version = @product.version_tilde_newest("1.2")
      tilde_version.version.should eql("1.3")
    end

    it "returns the right value" do 
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      version2 = Version.new
      version2.version = "1.2"
      @product.versions.push(version2)
      version3 = Version.new
      version3.version = "1.3"
      @product.versions.push(version3)
      version4 = Version.new
      version4.version = "1.4"
      @product.versions.push(version4)
      version5 = Version.new
      version5.version = "2.0"
      @product.versions.push(version5)

      tilde_version = @product.version_tilde_newest("1.2")
      tilde_version.version.should eql("1.4")
    end

    it "returns the right value" do 
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)
      version2 = Version.new
      version2.version = "1.2"
      @product.versions.push(version2)
      version3 = Version.new
      version3.version = "1.3"
      @product.versions.push(version3)
      version4 = Version.new
      version4.version = "1.4"
      @product.versions.push(version4)
      version5 = Version.new
      version5.version = "2.0"
      @product.versions.push(version5)

      tilde_version = @product.version_tilde_newest("1")
      tilde_version.version.should eql("1.4")
    end

  end

end