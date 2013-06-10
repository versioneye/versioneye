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

  describe "newest_version" do

    it "returns the newest stable version" do
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)

      version2 = Version.new
      version2.version = "1.1"
      @product.versions.push(version2)

      newest = @product.newest_version
      newest.version.should eql("1.1")
    end

    it "returns the newest stable version" do
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)

      version2 = Version.new
      version2.version = "1.1-dev"
      @product.versions.push(version2)

      newest = @product.newest_version
      newest.version.should eql("1.0")
    end

    it "returns the newest dev version" do
      version = Version.new
      version.version = "1.0"
      @product.versions.push(version)

      version2 = Version.new
      version2.version = "1.1-dev"
      @product.versions.push(version2)

      newest = VersionService.newest_version( @product.versions, VersionTagRecognizer::A_STABILITY_DEV )
      newest.version.should eql("1.1-dev")
    end

    it "returns the newest RC version" do
      version = Version.new
      version.version = "3.2.13"
      @product.versions.push(version)

      version2 = Version.new
      version2.version = "3.2.13.rc2"
      @product.versions.push(version2)

      newest = VersionService.newest_version( @product.versions, VersionTagRecognizer::A_STABILITY_RC )
      newest.version.should eql("3.2.13")
    end

    it "returns the newest dev version because there is no stable" do
      version = Version.new
      version.version = "1.0-Beta"
      @product.versions.push(version)

      version2 = Version.new
      version2.version = "1.1-dev"
      @product.versions.push(version2)

      newest = VersionService.newest_version(@product.versions)
      newest.version.should eql("1.1-dev")
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
