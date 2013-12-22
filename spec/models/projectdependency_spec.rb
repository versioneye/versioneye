require 'spec_helper'

describe Projectdependency do

  before(:each) do
    user              = UserFactory.create_new

    @project          = ProjectFactory.create_new( user )
    @project.language = Product::A_LANGUAGE_RUBY

    @product          = Product.new({:name => 'gomezify', :prod_key => 'gomezify'})
    @product.versions = Array.new
    @product.language = Product::A_LANGUAGE_RUBY
    @product.versions.push(Version.new({:version => '1.0'}))
    @product.version  = @product.versions.first.to_s
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
      product.language   = Product::A_LANGUAGE_PHP
      product.save

      dep                   = Projectdependency.new
      dep.prod_key          = product.prod_key
      dep.version_requested = "2.2.x-dev"
      dep.stability         = "dev"
      dep.language          = Product::A_LANGUAGE_PHP

      dep.outdated?.should be_false
      dep.version_current.should eql("2.2.x-dev")
    end

    it "is up to date" do
      prod_key           = "rails"
      product            = ProductFactory.create_for_gemfile(prod_key, "3.2.13")
      version_01         = Version.new
      version_01.version = "3.2.13.rc2"
      product.versions.push( version_01 )
      product.language   = Product::A_LANGUAGE_RUBY
      product.save

      dep                   = Projectdependency.new
      dep.prod_key          = "rails"
      dep.version_requested = "3.2.13.rc2"
      dep.language          = Product::A_LANGUAGE_RUBY
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

  describe "update_version_current" do

    it "doesnt update because prod_key is nil" do
      dep                   = ProjectdependencyFactory.create_new(@project, @product)
      dep.prod_key          = nil
      dep.version_requested = '0.1'
      dep.update_version_current
      dep.version_current.should eq(nil)
    end

    it "doesnt update because prod_key is empty" do
      dep                   = ProjectdependencyFactory.create_new(@project, @product)
      dep.prod_key          = ''
      dep.version_requested = '0.1'
      dep.update_version_current
      dep.version_current.should eq(nil)
    end

    it "doesnt update because prod_key, group_id and artifact_id are unknown" do
      dep                   = ProjectdependencyFactory.create_new(@project, @product)
      dep.prod_key          = 'gibts_doch_net'
      dep.group_id          = 'gibts_doch_net'
      dep.artifact_id       = 'gibts_doch_net'
      dep.version_requested = '0.1'
      dep.update_version_current
      dep.version_current.should eq(nil)
    end

    it "updates with the current verson" do
      dep                   = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = '0.1'
      dep.update_version_current
      dep.version_current.should eq('1.0')
    end

    it "updates with the current verson from different language" do
      user              = UserFactory.create_new

      project          = ProjectFactory.create_new( user )
      project.language = Product::A_LANGUAGE_JAVA

      product          = Product.new({:name => 'lamina', :prod_key => 'lamina', :group_id => 'lamina', :artifact_id => 'lamina' })
      product.versions = Array.new
      product.language = Product::A_LANGUAGE_CLOJURE
      product.versions.push(Version.new({:version => '1.0'}))
      product.version  = product.versions.first.to_s
      product.save

      dep                   = ProjectdependencyFactory.create_new(project, product)
      dep.language          = Product::A_LANGUAGE_JAVA
      dep.version_requested = '0.1'
      dep.update_version_current
      dep.version_current.should eq('1.0')
    end

  end

end
