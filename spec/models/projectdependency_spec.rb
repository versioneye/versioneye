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
      dep.version_requested = "2.2.x-dev"
      dep.stability = "dev"

      dep.outdated?.should be_false
      dep.version_current.should eql("2.2.x-dev")

      product.remove
    end

    it "is up to date" do
      prod_key = "rails"
      product = ProductFactory.create_for_gemfile(prod_key, "3.2.13")
      version_01 = Version.new
      version_01.version = "3.2.13.rc2"
      product.versions.push( version_01 )
      product.save

      dep = Projectdependency.new
      dep.prod_key = "rails"
      dep.version_requested = "3.2.13.rc2"
      dep.stability = VersionTagRecognizer.stability_tag_for dep.version_requested
      dep.outdated?.should be_true
    end

  end

end
