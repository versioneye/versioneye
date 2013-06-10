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

    it "returns the highest unststable because there is no stable" do
      @product.versions = Array.new
      version = Version.new
      version.version = "1.0-beta"
      @product.versions.push(version)

      version2 = Version.new
      version2.version = "1.1-beta"
      @product.versions.push(version2)

      version3 = Version.new
      version3.version = "1.2-dev"
      @product.versions.push(version3)

      @product.update_version_data
      @product.version.should eql("1.2-dev")
    end

  end

end
