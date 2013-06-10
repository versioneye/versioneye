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
      product.versions_empty?.should be_true
    end

    it "returns false" do
      product.versions = Array.new
      version = Version.new
      version.version = "1.0"
      product.versions.push(version)
      product.versions_empty?.should be_false
    end

    it "returns false" do
      product.versions = Array.new
      product.name = "test"
      product.prod_key = "gasgagasgj8623_junit/junit23"
      product.save
      version = Version.new
      version.version = "1.0"
      product.versions.push(version)
      prod = Product.find_by_key("gasgagasgj8623_junit/junit23")
      prod.versions_empty?.should be_false
    end

  end

end
