require 'spec_helper'

describe Product do
  
  before(:each) do
    @product = Product.new
  end
  
  after(:each) do 
    @product.remove
  end
  
  describe "dependencies_outdated?( scope )" do

    it "is not outdated" do 
      @product.prod_key = "junit/junit"
      @product.name = "junit"
      @product.language = Product::A_LANGUAGE_JAVA
      @product.prod_type = Project::A_TYPE_MAVEN2
      @product.save

      prod_1 = ProductFactory.create_new(1)
      prod_2 = ProductFactory.create_new(2)
      prod_3 = ProductFactory.create_new(3)
      prod_4 = ProductFactory.create_new(4)

      dep_1 = DependencyFacotry.create_dependency(@product, prod_1)
      dep_2 = DependencyFacotry.create_dependency(@product, prod_2)
      dep_3 = DependencyFacotry.create_dependency(@product, prod_3)
      dep_4 = DependencyFacotry.create_dependency(@product, prod_4)

      @product.dependencies(nil).size.should eq(4)
      @product.dependencies_outdated?().should be_false

      prod_1.remove
      prod_2.remove
      prod_3.remove
      prod_4.remove

      dep_1.remove
      dep_2.remove
      dep_3.remove
      dep_4.remove

    end

    it "is outdated" do 
      @product.prod_key = "junit/junit"
      @product.name = "junit"
      @product.language = Product::A_LANGUAGE_JAVA
      @product.prod_type = Project::A_TYPE_MAVEN2
      @product.save

      prod_1 = ProductFactory.create_new(1)
      prod_2 = ProductFactory.create_new(2)
      prod_3 = ProductFactory.create_new(3)
      prod_4 = ProductFactory.create_new(4)

      dep_1 = DependencyFacotry.create_dependency(@product, prod_1)
      dep_2 = DependencyFacotry.create_dependency(@product, prod_2)
      dep_3 = DependencyFacotry.create_dependency(@product, prod_3)
      dep_4 = DependencyFacotry.create_dependency(@product, prod_4)
      dep_4.version = "0.0"
      dep_4.save

      @product.dependencies(nil).size.should eq(4)
      @product.dependencies_outdated?().should be_true

      prod_1.remove
      prod_2.remove
      prod_3.remove
      prod_4.remove

      dep_1.remove
      dep_2.remove
      dep_3.remove
      dep_4.remove

    end

  end

end 