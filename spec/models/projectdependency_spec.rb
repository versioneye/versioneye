require 'spec_helper'

describe Projectdependency do

  before(:each) do
    user = UserFactory.create_new
    @project = ProjectFactory.create_new( user )
    @product          = Product.new
    @product.name     = "gomezify"
    @product.prod_key = "gomezify"
    @product.versions = Array.new
    version           = Version.new
    version.version   = "1.0"
    @product.versions.push(version)
    @product.version  = "1.0"
    @product.save
  end

  describe "outdated?" do

    it "is up to date" do
      dep                   = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "1.0"
      dep.outdated?.should be_false
      dep.unknown?.should  be_false
    end

    it "is outdated" do
      dep                   = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "0.9"
      dep.outdated?.should be_true
      dep.unknown?.should  be_false
    end

    it "is up to date" do
      dep                   = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "1.9"
      dep.outdated?.should be_false
      dep.unknown?.should  be_false
    end

    it "is up to date because it is GIT" do
      dep                   = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "GIT"
      dep.outdated?.should be_false
    end

    it "is up to date because it is PATH" do
      dep                   = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "PATH"
      dep.outdated?.should be_false
    end

    it "is up to date because it is unknown" do
      dep                   = ProjectdependencyFactory.create_new(@project, nil)
      dep.version_requested = "2.0.0"
      dep.outdated?.should be_false
      dep.unknown?.should  be_true
    end

    it "is up to date" do
      prod_key           = "symfony/locale_de"
      product            = ProductFactory.create_for_composer(prod_key, "2.2.x-dev")
      version_01         = Version.new
      version_01.version = "2.2.1"
      product.versions.push( version_01 )
      product.save

      dep                   = Projectdependency.new
      dep.prod_key          = product.prod_key
      dep.version_requested = "2.2.x-dev"
      dep.stability         = "dev"

      dep.outdated?.should be_false
      dep.version_current.should eql("2.2.x-dev")
    end

    it "is up to date" do
      prod_key           = "rails"
      product            = ProductFactory.create_for_gemfile(prod_key, "3.2.13")
      version_01         = Version.new
      version_01.version = "3.2.13.rc2"
      product.versions.push( version_01 )
      product.save

      dep                   = Projectdependency.new
      dep.prod_key          = "rails"
      dep.version_requested = "3.2.13.rc2"
      dep.stability         = VersionTagRecognizer.stability_tag_for dep.version_requested
      dep.outdated?.should be_true
    end

    it "checks the cache" do
      dep                   = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "1.0"
      dep.outdated?.should be_false
      dep.unknown?.should  be_false

      dep.version_requested = "0.1"
      dep.outdated?.should be_false
      dep.update_outdated!
      dep.outdated?.should be_true
    end

  end

end
