require 'spec_helper'

describe VersionService do

  let( :product ) { Product.new }

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

  describe "newest_version_number" do

    it "returns the newest version correct." do
      product.versions = Array.new
      ver = 1
      5.times{
        version = Version.new
        version.version = ver.to_s
        ver += 1
        product.versions.push(version)
      }
      version = product.newest_version_number
      version.should eql("5")
    end

    it "returns the newest version correct. With decimal numbers." do
      product.versions = Array.new
      ver = 1
      5.times{
        version = Version.new
        version.version = "1." + ver.to_s
        ver += 1
        product.versions.push(version)
      }
      version = product.newest_version_number
      version.should eql("1.5")
    end

    it "returns the newest version correct. With long numbers." do
      product.versions = Array.new

      version1 = Version.new
      version1.version = "1.2.2"
      product.versions.push(version1)

      version2 = Version.new
      version2.version = "1.2.29"
      product.versions.push(version2)

      version3 = Version.new
      version3.version = "1.3"
      product.versions.push(version3)

      version = product.newest_version_number
      version.should eql("1.3")
    end

    it "returns the newest version correct. With long numbers. Wariant 2." do
      product.versions = Array.new

      version1 = Version.new
      version1.version = "1.22"
      product.versions.push(version1)

      version2 = Version.new
      version2.version = "1.229"
      product.versions.push(version2)

      version3 = Version.new
      version3.version = "1.30"
      product.versions.push(version3)

      version = product.newest_version_number
      version.should eql("1.229")
    end

  end

  describe "static newest_version_from" do

    it "returns the correct version" do
      versions = Array.new
      version1 = Version.new
      version1.version = "1.22"
      versions.push(version1)

      version2 = Version.new
      version2.version = "1.229"
      versions.push(version2)

      version3 = Version.new
      version3.version = "1.30"
      versions.push(version3)

      Product.newest_version_from(versions).version.should eql("1.229")
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
      product.versions.push(version)
      product.wouldbenewest?("1.0").should be_false
    end
    it "returns false for smaller version" do
      version = Version.new
      version.version = "1.0"
      product.versions.push(version)
      product.wouldbenewest?("0.9").should be_false
    end
    it "returns true for bigger version" do
      version = Version.new
      version.version = "1.0"
      product.versions.push(version)
      product.wouldbenewest?("1.1").should be_true
    end
    it "returns true for much bigger version" do
      version = Version.new
      version.version = "1.9"
      product.versions.push(version)
      product.wouldbenewest?("1.10").should be_true
    end

  end

  describe "versions_start_with" do

    it "returns an empty array" do
      product.versions = nil
      product.versions_start_with("1.0").should eql([])
    end

    it "returns the correct array" do
      version = Version.new
      version.version = "1.1"
      version2 = Version.new
      version2.version = "1.2"
      version3 = Version.new
      version3.version = "1.3"
      version4 = Version.new
      version4.version = "2.0"
      product.versions.push(version)
      product.versions.push(version2)
      product.versions.push(version3)
      product.versions.push(version4)
      results = product.versions_start_with("1")
      results.size.should eql(3)
      results.first.version.should eql(version.version)
      results.last.version.should eql(version3.version)
      results = product.versions_start_with("1.")
      results.size.should eql(3)
      results.first.version.should eql(version.version)
      results.last.version.should eql(version3.version)
    end

  end

  describe "version_approximately_greater_than_starter" do

    it "returns the given value" do
      Product.version_approximately_greater_than_starter("1.0").should eql("1.")
    end
    it "returns the given value" do
      Product.version_approximately_greater_than_starter("1.2").should eql("1.2.")
    end

  end

end
