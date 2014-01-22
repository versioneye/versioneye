require 'spec_helper'

describe DependencyService do

  describe "outdated?" do
    let(:product){FactoryGirl.build(:product, 
                                    name: "test1", 
                                    prod_key: "test1", 
                                    language: "Ruby",
                                    prod_type: Project::A_TYPE_RUBYGEMS)}

    before :each do
    end

    after :each do
      Product.delete_all
    end

    it "is outdated" do
      product.versions << Version.new({version: "1.0" })
      product.save
      dependency = Dependency.new version:      "0.1",
                                  dep_prod_key: product.prod_key,
                                  prod_type:    product.prod_type,
                                  language:     product.language
      DependencyService.outdated?( dependency ).should be_true
    end

    it "is not outdated, because it's equal" do 
      product.versions << Version.new({:version => "1.0.0"})
      product.version = "1.0.0"
      product.save

      dependency              = Dependency.new
      dependency.version      = product.version
      dependency.dep_prod_key = product.prod_key
      dependency.prod_type    = product.prod_type
      dependency.language     = product.language
      DependencyService.outdated?( dependency ).should be_false
    end

    it "is not outdated, because it's a range" do
      product.versions <<  Version.new({:version => "1.0.0"})
      product.version = "1.0.0"
      product.save

      dependency = Dependency.new version: ">= 0.9.0",
                                  dep_prod_key: product.prod_key,
                                  prod_type: product.prod_type,
                                  language: product.language

      DependencyService.outdated?( dependency ).should be_false
      dependency.version.should eql(">= 0.9.0")
    end

    it "is not outdated, because it's higher" do
      product = ProductFactory.create_new(1)
      product.versions.push Version.new({ :version => "1.0" })
      product.save

      dependency = Dependency.new version: "100000.2",
                                  language: product.language,
                                  dep_prod_key: product.prod_key

      DependencyService.outdated?( dependency ).should be_false
    end

    it "is not outdated, because unknown dep" do
      dependency         = Dependency.new version: "0.1"
      DependencyService.outdated?( dependency ).should be_false
    end

  end

  describe "dependencies_outdated?( scope )" do

    it "is not outdated" do
      product           = Product.new
      product.prod_key  = "junit/junit"
      product.name      = "junit"
      product.language  = Product::A_LANGUAGE_JAVA
      product.prod_type = Project::A_TYPE_MAVEN2
      product.save

      prod_1 = ProductFactory.create_new(1)
      prod_2 = ProductFactory.create_new(2)
      prod_3 = ProductFactory.create_new(3)
      prod_4 = ProductFactory.create_new(4)

      DependencyFacotry.create_new(product, prod_1)
      DependencyFacotry.create_new(product, prod_2)
      DependencyFacotry.create_new(product, prod_3)
      DependencyFacotry.create_new(product, prod_4)

      product.dependencies(nil).size.should eq(4)
      DependencyService.dependencies_outdated?( product.dependencies(nil) ).should be_false
    end

    it "is outdated" do
      product           = Product.new
      product.prod_key  = "junit/junit"
      product.name      = "junit"
      product.language  = Product::A_LANGUAGE_JAVA
      product.prod_type = Project::A_TYPE_MAVEN2
      product.save

      prod_1 = ProductFactory.create_new(1)
      prod_2 = ProductFactory.create_new(2)
      prod_3 = ProductFactory.create_new(3)
      prod_4 = ProductFactory.create_new(4)

      DependencyFacotry.create_new(product, prod_1)
      DependencyFacotry.create_new(product, prod_2)
      DependencyFacotry.create_new(product, prod_3)
      dep_4 = DependencyFacotry.create_new(product, prod_4)
      dep_4.version = "0.0"
      dep_4.save

      product.dependencies(nil).size.should eq(4)
      DependencyService.dependencies_outdated?( product.dependencies(nil) ).should be_true
    end

  end

end
