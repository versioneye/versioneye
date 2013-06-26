require 'spec_helper'

describe Dependency do

  describe "gem_version_parsed" do

    it "returns valid value" do
      product = Product.new
      product.versions = Array.new
      product.name = "test"
      product.prod_key = "gasgagasgj8623_jun44444it/juasgnit23afsg"
      product.language = Product::A_LANGUAGE_RUBY

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
      dependency.language = product.language
      dependency.version = "~> 1.0"
      dependency.dep_prod_key = product.prod_key
      dependency.gem_version_parsed().should eql("1.2")

      product.remove
    end

    it "returns valid value" do
      product = Product.new
      product.versions = Array.new
      product.name = "test"
      product.prod_key = "huj_buuuuu"
      product.language = Product::A_LANGUAGE_RUBY

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
      dependency.language = product.language
      dependency.gem_version_parsed().should eql("2.2.9")

      dependency.version = "~> 2.0"
      dependency.dep_prod_key = product.prod_key
      dependency.gem_version_parsed().should eql("2.3")

      product.remove
    end

  end

  describe "packagist_version_parsed" do

    it "returns valid value" do
      product = Product.new
      product.versions = Array.new
      product.name = "test"
      product.language = Product::A_LANGUAGE_RUBY
      product.prod_key = "gasgj8623_jun44444it/juat23afsg"

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
      dependency.language = product.language
      dependency.version = "~1.0"
      dependency.dep_prod_key = product.prod_key
      dependency.packagist_version_parsed().should eql("1.2")

      product.remove
    end

    it "returns valid value" do
      product = Product.new
      product.versions = Array.new
      product.name = "test"
      product.prod_key = "huj_buuuuu"
      product.language = Product::A_LANGUAGE_RUBY

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
      dependency.language = product.language
      dependency.version = "~2.2"
      dependency.dep_prod_key = product.prod_key
      dependency.packagist_version_parsed().should eql("2.2.9")

      dependency.version = "~2.0"
      dependency.dep_prod_key = product.prod_key
      dependency.packagist_version_parsed().should eql("2.3")

      product.remove
    end

  end

  describe "npm_version_parsed" do

    it "returns valid value" do
      product = Product.new
      product.versions = Array.new
      product.name = "test"
      product.language = Product::A_LANGUAGE_RUBY
      product.prod_key = "gasgj8623_jun44444it/juat23afsg"

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
      dependency.language = product.language
      dependency.version = "~1.0"
      dependency.dep_prod_key = product.prod_key
      dependency.npm_version_parsed().should eql("1.2")

      product.remove
    end

  end

  context "find_by_context" do

    describe "find_by" do

      before(:each) do
        @dependency = Dependency.new({ :language => Product::A_LANGUAGE_RUBY, :name => "bodo/bodo", :version => "1.0.1", :dep_prod_key => "bada/bada", :prod_key => "bum/bum", :prod_version => "1.1.1"})
        @dependency.save
      end

      after(:each) do
        @dependency.remove
      end

      it "returns the right dep" do
        dep = Dependency.find_by( Product::A_LANGUAGE_RUBY, "bum/bum", "1.1.1", "bodo/bodo", "1.0.1", "bada/bada")
        dep.should_not be_nil
        dep.name.should eql("bodo/bodo")
      end

      it "returns nil" do
        dep = Dependency.find_by( Product::A_LANGUAGE_RUBY, "bum/bum", "1.1.0", "bodo/bodo", "1.0.1", "bada/bada")
        dep.should be_nil
      end

    end

  end

end
