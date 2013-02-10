require 'spec_helper'

describe ComposerLockParser do
  describe "parse" do
    before :each do
      @project_file_url = "https://s3.amazonaws.com/veye_test_env/composer.lock"
      @product1 = ProductFactory.create_for_composer("doctrine/annotations", "1.0")
      @product1.save

      @product2 = ProductFactory.create_for_composer("doctrine/cache", "1.0")
      @product2.save

      @product3 = ProductFactory.create_for_composer("doctrine/collections", "1.0")
      @product3.save
 
      @product4 = ProductFactory.create_for_composer("doctrine/common", "2.4.x-dev")
      @product4.save
 
      @product5 = ProductFactory.create_for_composer("doctrine/dbal", "2.4.x-dev")
      @product5.save
      
      @product6 = ProductFactory.create_for_composer("doctrine/doctrine-module", 
                                                     "0.7.1")
      @product6.save
  
      @product7 = ProductFactory.create_for_composer("doctrine/doctrine-orm-module", 
                                                     "0.8.x-dev")
      @product7.save
   
      @product8 = ProductFactory.create_for_composer("doctrine/inflector", "1.0")
      @product8.save
    
      @product9 = ProductFactory.create_for_composer("doctrine/lexer", "1.0")
      @product9.save
     
      @product10 = ProductFactory.create_for_composer("doctrine/orm", "2.4.x-dev")
      @product10.save
   
      @product11 = ProductFactory.create_for_composer("kablau-joustra/kj-sencha", 
                                                      "dev-master")
      @product11.save
      
      @product12 = ProductFactory.create_for_composer("kriswallsmith/assetic", 
                                                      "1.1-dev")
      @product12.save
      
      @product13 = ProductFactory.create_for_composer("rwoverdijk/assetmanager", 
                                                      "1.2.6")
      @product13.save
      
      @product14 = ProductFactory.create_for_composer("symfony/console", "2.2-dev")
      @product14.save
      
      @product15 = ProductFactory.create_for_composer("symfony/process", "2.2-dev")
      @product15.save
      
      @product16 = ProductFactory.create_for_composer("zendframework/zend-developer-tools", 
                                                      "dev-master")

      @product16.save
       
      @product17 = ProductFactory.create_for_composer("zendframework/zendframework", 
                                                      "2.1-dev")
      @product17.save
 
    end
  
    after :each do
      Product.where().delete
    end

    it "parses correctly from S3 file" do
      parser = ComposerLockParser.new
      project = parser.parse @project_file_url
      project.should_not be_nil
      project.dependencies.count.should eql(17)
      
      dep1 = project.dependencies.shift
      dep1.name.should eql(@product1.name)
      dep1.version_requested.should eql(@product1.version)
      dep1.comperator.should eql("=")

      dep2 = project.dependencies.shift
      dep2.name.should eql(@product2.name)
      dep2.version_requested.should eql(@product2.version)
      dep2.comperator.should eql("=")
   
      dep3 = project.dependencies.shift
      dep3.name.should eql(@product3.name)
      dep3.version_requested.should eql(@product3.version)
      dep3.comperator.should eql("=")

      dep4 = project.dependencies.shift
      dep4.name.should eql(@product4.name)
      dep4.version_requested.should eql(@product4.version)
      dep4.comperator.should eql("=")

      dep5 = project.dependencies.shift
      dep5.name.should eql(@product5.name)
      dep5.version_requested.should eql(@product5.version)
      dep5.comperator.should eql("=")

      dep6 = project.dependencies.shift
      dep6.name.should eql(@product6.name)
      dep6.version_requested.should eql(@product6.version)
      dep6.comperator.should eql("=")

      dep7 = project.dependencies.shift
      dep7.name.should eql(@product7.name)
      dep7.version_requested.should eql(@product7.version)
      dep7.comperator.should eql("=")

      dep8 = project.dependencies.shift
      dep8.name.should eql(@product8.name)
      dep8.version_requested.should eql(@product8.version)
      dep8.comperator.should eql("=")

      dep9 = project.dependencies.shift
      dep9.name.should eql(@product9.name)
      dep9.version_requested.should eql(@product9.version)
      dep9.comperator.should eql("=")

      dep10 = project.dependencies.shift
      dep10.name.should eql(@product10.name)
      dep10.version_requested.should eql(@product10.version)
      dep10.comperator.should eql("=")

      dep11 = project.dependencies.shift
      dep11.name.should eql(@product11.name)
      dep11.version_requested.should eql(@product11.version)
      dep11.comperator.should eql("=")

      dep12 = project.dependencies.shift
      dep12.name.should eql(@product12.name)
      dep12.version_requested.should eql(@product12.version)
      dep12.comperator.should eql("=")

      dep13 = project.dependencies.shift
      dep13.name.should eql(@product13.name)
      dep13.version_requested.should eql(@product13.version)
      dep13.comperator.should eql("=")

      dep14 = project.dependencies.shift
      dep14.name.should eql(@product14.name)
      dep14.version_requested.should eql(@product14.version)
      dep14.comperator.should eql("=")

      dep15 = project.dependencies.shift
      dep15.name.should eql(@product15.name)
      dep15.version_requested.should eql(@product15.version)
      dep15.comperator.should eql("=")

      dep16 = project.dependencies.shift
      dep16.name.should eql(@product16.name)
      dep16.version_requested.should eql(@product16.version)
      dep16.comperator.should eql("=")

      dep17 = project.dependencies.shift
      dep17.name.should eql(@product17.name)
      dep17.version_requested.should eql(@product17.version)
      dep17.comperator.should eql("=")

    end
  end
end
