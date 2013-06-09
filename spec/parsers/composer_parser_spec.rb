require 'spec_helper'

describe ComposerParser do

  describe "parse" do

    before :all do
      product_01 = ProductFactory.create_for_composer("symfony/symfony", "2.0.7")
      version_01_01 = Version.new
      version_01_01.version = "2.0.7-dev"
      product_01.versions.push( version_01_01 )
      product_01.save

      product_02 = ProductFactory.create_for_composer("symfony/doctrine-bundle", "2.0.7")
      product_02.save

      product_03 = ProductFactory.create_for_composer("symfony/process", "2.0.7")
      version_03_01 = Version.new
      version_03_01.version = "2.0.6"
      product_03.versions.push( version_03_01 )
      version_03_02 = Version.new
      version_03_02.version = "dev-master"
      product_03.versions.push( version_03_02 )
      product_03.save

      product_04 = ProductFactory.create_for_composer("symfony/browser-kit", "2.0.7")
      version_04_01 = Version.new
      version_04_01.version = "2.0.6"
      product_04.versions.push( version_04_01 )
      product_04.save

      product_05 = ProductFactory.create_for_composer("symfony/security-bundle", "2.0.7")
      version_05_01 = Version.new
      version_05_01.version = "2.0.6"
      product_05.versions.push( version_05_01 )
      product_05.save

      product_06 = ProductFactory.create_for_composer("symfony/locale", "2.0.7")
      version_06_01 = Version.new
      version_06_01.version = "2.0.8"
      product_06.versions.push( version_06_01 )
      product_06.save

      product_07 = ProductFactory.create_for_composer("symfony/yaml", "2.0.8")
      version_07_01 = Version.new
      version_07_01.version = "2.0.7"
      product_07.versions.push( version_07_01 )
      product_07.save

      product_08 = ProductFactory.create_for_composer("symfony/http-kernel", "2.0.7")
      version_08_01 = Version.new
      version_08_01.version = "2.0.6"
      product_08.versions.push( version_08_01 )
      product_08.save

      product_09 = ProductFactory.create_for_composer("twig/twig", "2.0.0")
      version_09_01 = Version.new
      version_09_01.version = "1.9.0"
      product_09.versions.push( version_09_01 )
      version_09_02 = Version.new
      version_09_02.version = "1.9.1"
      product_09.versions.push( version_09_02 )
      version_09_03 = Version.new
      version_09_03.version = "1.9.9"
      product_09.versions.push( version_09_03 )
      product_09.save

      product_10 = ProductFactory.create_for_composer("doctrine/common", "2.4")
      version_10_01 = Version.new
      version_10_01.version = "2.2"
      product_10.versions.push( version_10_01 )
      version_10_02 = Version.new
      version_10_02.version = "2.3"
      product_10.versions.push( version_10_02 )
      version_10_03 = Version.new
      version_10_03.version = "2.1"
      product_10.versions.push( version_10_03 )
      product_10.save

      product_11 = ProductFactory.create_for_composer("symfony/console", "2.0.10")
      version_11_01 = Version.new
      version_11_01.version = "2.0.0"
      product_11.versions.push( version_11_01 )
      version_11_02 = Version.new
      version_11_02.version = "2.0.6"
      product_11.versions.push( version_11_02 )
      version_11_03 = Version.new
      version_11_03.version = "2.0.7"
      product_11.versions.push( version_11_03 )
      version_11_04 = Version.new
      version_11_04.version = "2.2.0-BETA2"
      product_11.versions.push( version_11_04 )
      product_11.save


      product_12 = ProductFactory.create_for_composer("symfony/translation", "2.2.x-dev")
      version_12_01 = Version.new
      version_12_01.version = "2.2.0"
      product_12.versions.push( version_12_01 )
      version_12_02 = Version.new
      version_12_02.version = "2.2.1"
      product_12.versions.push( version_12_02 )
      version_12_03 = Version.new
      version_12_03.version = "2.2.0-alpha"
      product_12.versions.push( version_12_03 )
      version_12_04 = Version.new
      version_12_04.version = "2.2.0-BETA2"
      product_12.versions.push( version_12_04 )
      product_12.save


      product_13 = ProductFactory.create_for_composer("symfony/filesystem", "2.2.x-dev")
      version_13_01 = Version.new
      version_13_01.version = "2.2.1"
      product_13.versions.push( version_13_01 )
      version_13_02 = Version.new
      version_13_02.version = "2.2.0-BETA2"
      product_13.versions.push( version_13_02 )
      product_13.save


      product_14 = ProductFactory.create_for_composer("symfony/stopwatch", "2.2.x-dev")
      version_14_01 = Version.new
      version_14_01.version = "2.2.1"
      product_14.versions.push( version_14_01 )
      product_14.save


      product_16 = ProductFactory.create_for_composer("symfony/finder", "2.2.1")
      version_16_01 = Version.new
      version_16_01.version = "2.2.0"
      product_16.versions.push( version_16_01 )
      product_16.save

      product_17 = ProductFactory.create_for_composer("symfony/config", "2.2.1")
      version_17_01 = Version.new
      version_17_01.version = "2.2.1"
      product_17.versions.push( version_17_01 )
      product_17.save
    end

    after :all do
      Product.where().delete
    end


    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
    end

    it "parse from https the file correctly" do
      parser = ComposerParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/composer.json")
      project.should_not be_nil
    end

    it "parse from http the file correctly" do
      parser = ComposerParser.new
      project = parser.parse("http://s3.amazonaws.com/veye_test_env/composer.json")
      project.should_not be_nil
      project.dependencies.size.should eql(17)

      dep_01 = fetch_by_name(project.dependencies, "symfony/symfony")
      dep_01.name.should eql("symfony/symfony")
      dep_01.version_requested.should eql("2.0.7")
      dep_01.version_current.should eql("2.0.7")
      dep_01.stability.should eql("stable")
      dep_01.comperator.should eql("=")

      dep_02 = fetch_by_name(project.dependencies, "symfony/doctrine-bundle")
      dep_02.name.should eql("symfony/doctrine-bundle")
      dep_02.version_requested.should eql("2.0.7")
      dep_02.version_current.should eql("2.0.7")
      dep_02.comperator.should eql("=")

      dep_03 = fetch_by_name(project.dependencies, "symfony/process")
      dep_03.name.should eql("symfony/process")
      dep_03.version_requested.should eql("2.0.7")
      dep_03.version_current.should eql("2.0.7")
      dep_03.comperator.should eql("=")

      dep_04 = fetch_by_name(project.dependencies, "symfony/browser-kit")
      dep_04.name.should eql("symfony/browser-kit")
      dep_04.version_requested.should eql("2.0.7")
      dep_04.version_current.should eql("2.0.7")
      dep_04.comperator.should eql("!=")

      dep_05 = fetch_by_name(project.dependencies, "symfony/security-bundle")
      dep_05.name.should eql("symfony/security-bundle")
      dep_05.version_requested.should eql("2.0.7")
      dep_05.version_current.should eql("2.0.7")
      dep_05.comperator.should eql(">=")

      dep_06 = fetch_by_name(project.dependencies, "symfony/locale")
      dep_06.name.should eql("symfony/locale")
      dep_06.version_requested.should eql("2.0.7")
      dep_06.version_current.should eql("2.0.8")
      dep_06.comperator.should eql("<=")

      dep_07 = fetch_by_name(project.dependencies, "symfony/yaml")
      dep_07.name.should eql("symfony/yaml")
      dep_07.version_requested.should eql("2.0.7")
      dep_07.version_current.should eql("2.0.8")
      dep_07.comperator.should eql("<")

      dep_08 = fetch_by_name(project.dependencies, "symfony/http-kernel")
      dep_08.name.should eql("symfony/http-kernel")
      dep_08.version_requested.should eql("2.0.7")
      dep_08.version_current.should eql("2.0.7")
      dep_08.comperator.should eql(">")

      dep_09 = fetch_by_name(project.dependencies, "twig/twig")
      dep_09.name.should eql("twig/twig")
      dep_09.version_requested.should eql("1.9.9")
      dep_09.version_current.should eql("2.0.0")
      dep_09.version_label.should eql(">=1.9.1,<2.0.0")
      dep_09.comperator.should eql("=")

      dep_10 = fetch_by_name(project.dependencies, "doctrine/common")
      dep_10.name.should eql("doctrine/common")
      dep_10.version_requested.should eql("2.3")
      dep_10.version_current.should eql("2.4")
      dep_10.comperator.should eql("=")

      dep_11 = fetch_by_name(project.dependencies, "symfony/console")
      dep_11.name.should eql("symfony/console")
      dep_11.version_requested.should eql("2.0.7")
      dep_11.version_current.should eql("2.0.10")
      dep_11.comperator.should eql("=")
      dep_11.stability.should eql("stable")

      dep_12 = fetch_by_name(project.dependencies, "symfony/translation")
      dep_12.name.should eql("symfony/translation")
      dep_12.version_requested.should eql("2.2.x-dev")
      dep_12.version_current.should eql("2.2.x-dev")
      dep_12.comperator.should eql("=")
      dep_12.outdated.should be_false
      dep_12.stability.should eql("dev")

      dep_13 = fetch_by_name(project.dependencies, "symfony/filesystem")
      dep_13.name.should eql("symfony/filesystem")
      dep_13.version_label.should eql("2.2.*@dev")
      dep_13.version_requested.should eql("2.2.x-dev")
      dep_13.version_current.should   eql("2.2.x-dev")
      dep_13.outdated.should be_false
      dep_13.comperator.should eql("=")

      dep_14 = fetch_by_name(project.dependencies, "symfony/stopwatch")
      dep_14.name.should eql("symfony/stopwatch")
      dep_14.version_label.should eql("2.2.*@stable")
      dep_14.version_requested.should eql("2.2.1")
      dep_14.version_current.should   eql("2.2.1")
      dep_14.outdated.should be_false
      dep_14.comperator.should eql("=")
      dep_14.stability.should eql("stable")

      dep_16 = fetch_by_name(project.dependencies, "symfony/finder")
      dep_16.name.should eql("symfony/finder")
      dep_16.version_label.should eql("@dev")
      dep_16.version_requested.should eql("2.2.1")
      dep_16.version_current.should   eql("2.2.1")
      dep_16.comperator.should eql("=")

      dep_17 = fetch_by_name(project.dependencies, "symfony/config")
      dep_17.name.should eql("symfony/config")
      dep_17.version_label.should eql("~2.2")
      dep_17.version_requested.should eql("2.2.1")
      dep_17.version_current.should   eql("2.2.1")
      dep_17.comperator.should eql("~")
    end

  end

  describe "dependency_in_repositories?" do

    it "returns false because of nil parameters" do
      parser = ComposerParser.new
      parser.dependency_in_repositories?(nil, nil).should be_false
    end

  end

end
