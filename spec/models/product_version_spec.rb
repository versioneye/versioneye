require 'spec_helper'

describe Product do

  let( :product ){ Product.new({:language => Product::A_LANGUAGE_RUBY, :prod_type => Project::A_TYPE_RUBYGEMS }) }

  describe "versions_empty?" do

    it "returns true" do
      product.versions_empty?.should be_true
    end

    it "returns false" do
      product.name = "test"
      product.prod_key = "gasgagasgj8623_junit/junit23"
      product.versions = Array.new
      product.versions.push( Version.new({ :version => "1.0" }) )
      product.versions_empty?.should be_false
    end

    it "returns false" do
      product.versions = Array.new
      product.name = "test"
      product.prod_key = "gasgagasgj8623_junit/junit23"
      product.save
      product.versions.push( Version.new({ :version => "1.0" }) )
      prod = Product.find_by_key("gasgagasgj8623_junit/junit23")
      prod.versions_empty?.should be_false
    end

  end

end
