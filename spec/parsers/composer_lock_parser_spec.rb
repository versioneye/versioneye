require 'spec_helper'

describe ComposerLockParser do

  describe "parse" do

    before :each do
      @products = Array.new

      @project_file_url = "https://s3.amazonaws.com/veye_test_env/composer.lock"

      @product1  = ProductFactory.create_for_composer("doctrine/annotations", "1.0")
      @product2  = ProductFactory.create_for_composer("doctrine/cache", "1.0")
      @product3  = ProductFactory.create_for_composer("doctrine/collections", "1.0")
      @product4  = ProductFactory.create_for_composer("doctrine/common", "2.4.x-dev")
      @product5  = ProductFactory.create_for_composer("doctrine/dbal", "2.4.x-dev")
      @product6  = ProductFactory.create_for_composer("doctrine/doctrine-module", "0.7.1")
      @product7  = ProductFactory.create_for_composer("doctrine/doctrine-orm-module", "0.8.x-dev")
      @product8  = ProductFactory.create_for_composer("doctrine/inflector", "1.0")
      @product9  = ProductFactory.create_for_composer("doctrine/lexer", "1.0")
      @product10 = ProductFactory.create_for_composer("doctrine/orm", "2.4.x-dev")
      @product11 = ProductFactory.create_for_composer("kablau-joustra/kj-sencha", "dev-master")
      @product12 = ProductFactory.create_for_composer("kriswallsmith/assetic", "1.1-dev")
      @product13 = ProductFactory.create_for_composer("rwoverdijk/assetmanager", "1.2.6")
      @product14 = ProductFactory.create_for_composer("symfony/console", "2.2-dev")
      @product15 = ProductFactory.create_for_composer("symfony/process", "2.2-dev")
      @product16 = ProductFactory.create_for_composer("zendframework/zend-developer-tools", "dev-master")
      @product17 = ProductFactory.create_for_composer("zendframework/zendframework", "2.1-dev")

      @products.push @product1
      @products.push @product2
      @products.push @product3
      @products.push @product4
      @products.push @product5
      @products.push @product6
      @products.push @product7
      @products.push @product8
      @products.push @product9
      @products.push @product10
      @products.push @product11
      @products.push @product12
      @products.push @product13
      @products.push @product14
      @products.push @product15
      @products.push @product16
      @products.push @product17

      @products.each do |product|
        product.save
      end
    end

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
    end

    it "parses correctly from S3 file" do
      parser = ComposerLockParser.new
      project = parser.parse @project_file_url
      project.should_not be_nil
      project.dependencies.size.should eql(17)

      @products.each do |product|
        dep1 = fetch_by_name(project.dependencies, product.name)
        dep1.should_not be_nil
        dep1.name.should eql( product.name )
        dep1.version_requested.should eql( product.version )
        dep1.comperator.should eql("=")
      end

    end

  end

end
