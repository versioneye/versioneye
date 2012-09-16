require 'spec_helper'

describe ComposerParser do
  
  describe "parse" do 
    
    it "parse from https the file correctly" do
      project = ComposerParser.parse("https://s3.amazonaws.com/veye_test_env/composer.json")
      project.should_not be_nil
    end
    
    it "parse from http the file correctly" do
      product_01 = ProductFactory.create_for_composer("symfony/symfony", "2.0.7")
      product_01.save

      product_02 = ProductFactory.create_for_composer("symfony/doctrine-bundle", "2.0.7")
      product_02.save

      product_03 = ProductFactory.create_for_composer("symfony/process", "2.0.7")
      version_03_01 = Version.new 
      version_03_01.version = "2.0.6"
      product_03.versions.push( version_03_01 )
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
      product_11.save

      project = ComposerParser.parse("http://s3.amazonaws.com/veye_test_env/composer.json")
      project.should_not be_nil
      project.dependencies.count.should eql(11)

      dep_01 = project.dependencies.first
      dep_01.name.should eql("symfony/symfony")
      dep_01.version_requested.should eql("2.0.7")
      dep_01.version_current.should eql("2.0.7")
      dep_01.comperator.should eql("=")

      dep_02 = project.dependencies[1]
      dep_02.name.should eql("symfony/doctrine-bundle")
      dep_02.version_requested.should eql("2.0.7")
      dep_02.version_current.should eql("2.0.7")
      dep_02.comperator.should eql("=")

      dep_03 = project.dependencies[2]
      dep_03.name.should eql("symfony/process")
      dep_03.version_requested.should eql("2.0.7")
      dep_03.version_current.should eql("2.0.7")
      dep_03.comperator.should eql("=")

      dep_04 = project.dependencies[3]
      dep_04.name.should eql("symfony/browser-kit")
      dep_04.version_requested.should eql("2.0.7")
      dep_04.version_current.should eql("2.0.7")
      dep_04.comperator.should eql("!=")

      dep_05 = project.dependencies[4]
      dep_05.name.should eql("symfony/security-bundle")
      dep_05.version_requested.should eql("2.0.7")
      dep_05.version_current.should eql("2.0.7")
      dep_05.comperator.should eql(">=")

      dep_06 = project.dependencies[5]
      dep_06.name.should eql("symfony/locale")
      dep_06.version_requested.should eql("2.0.7")
      dep_06.version_current.should eql("2.0.7")
      dep_06.comperator.should eql("<=")

      dep_07 = project.dependencies[6]
      dep_07.name.should eql("symfony/yaml")
      dep_07.version_requested.should eql("2.0.7")
      dep_07.version_current.should eql("2.0.8")
      dep_07.comperator.should eql("<")

      dep_08 = project.dependencies[7]
      dep_08.name.should eql("symfony/http-kernel")
      dep_08.version_requested.should eql("2.0.7")
      dep_08.version_current.should eql("2.0.7")
      dep_08.comperator.should eql(">")

      dep_09 = project.dependencies[8]
      dep_09.name.should eql("twig/twig")
      dep_09.version_requested.should eql("1.9.9")
      dep_09.version_current.should eql("2.0.0")
      dep_09.version_label.should eql(">=1.9.1,<2.0.0")
      dep_09.comperator.should eql("=")

      dep_10 = project.dependencies[9]
      dep_10.name.should eql("doctrine/common")
      dep_10.version_requested.should eql("2.3")
      dep_10.version_current.should eql("2.4")
      dep_10.comperator.should eql("=")

      dep_11 = project.dependencies[10]
      dep_11.name.should eql("symfony/console")
      dep_11.version_requested.should eql("2.0.7")
      dep_11.version_current.should eql("2.0.10")
      dep_11.comperator.should eql("=")

      product_01.remove
      product_02.remove
      product_03.remove
      product_04.remove
      product_05.remove
      product_06.remove
      product_07.remove
      product_08.remove
      product_09.remove
      product_10.remove
      product_11.remove

    end
    
  end
  
end