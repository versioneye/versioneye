require 'spec_helper'

describe Product do

  let( :product ) { Product.new }

  describe "find_by_key" do

    it "return nil. Because input is nil" do
      result = described_class.find_by_key(nil)
      result.should be_nil
    end

    it "return nil. Because input is empty" do
      result = described_class.find_by_key("  ")
      result.should be_nil
    end

    it "return nil. Because there are no results." do
      result = described_class.find_by_key("gasflasjgfaskjgas848asjgfasgfasgf")
      result.should be_nil
    end

  end

  describe "find_by_lang_key" do

    it "return nil. Because input is nil" do
      result = described_class.find_by_lang_key(nil, nil)
      result.should be_nil
    end

    it "return nil. Because input is empty" do
      product1 = ProductFactory.create_for_gemfile("bee", "1.4.0")
      product1.versions.push( Version.new({version: "1.4.0"}) )
      product1.save
      result = described_class.find_by_lang_key( Product::A_LANGUAGE_JAVA, "bee" )
      result.should be_nil
      result = described_class.find_by_lang_key( Product::A_LANGUAGE_RUBY, "bee" )
      result.should_not be_nil
      result.prod_key.should eql("bee")
    end

  end

  describe "http_links" do

    it "returns an empty array" do
      product.http_links.size.should eq(0)
    end

    it "returns one link" do
      link = Versionlink.new
      link.prod_key = product.prod_key
      link.link = "http://link.de"
      link.name = "Name"
      link.save
      product.http_links.size.should eq(1)
      link.remove
    end

    it "returns an empty array" do
      link = Versionlink.new
      link.prod_key = product.prod_key
      link.link = "http://link.de"
      link.version_id = "nope"
      link.name = "Name"
      link.save
      product.http_links.size.should eq(0)
      link.remove
    end

    it "returns 1 link" do
      link = Versionlink.new
      link.prod_key = product.prod_key
      link.link = "http://link.de"
      link.version_id = "1.1"
      link.name = "Name"
      link.save
      product.version = "1.1"
      product.http_version_links.size.should eq(1)
      link.remove
    end

  end

  describe "find_by_group_and_artifact" do

    it "returns nil because of wrong parameters" do
      described_class.find_by_group_and_artifact("bullshit", "bingo").should be_nil
    end

    it "returns the correct product" do
      group = "junit56"
      artifact = "junit23"
      product.versions = Array.new
      product.name = "test"
      product.prod_key = "#{group}/#{artifact}"
      product.group_id = group
      product.artifact_id = artifact
      product.save
      version = Version.new
      prod = described_class.find_by_group_and_artifact(group, artifact)
      prod.should_not be_nil
      prod.group_id.should eql(group)
      prod.artifact_id.should eql(artifact)
    end

  end

  describe "downcase_array" do
    it " - downcases the array" do
      elements = Array.new
      elements.push "Hallo"
      elements.push "BamboO"
      new_elements = described_class.downcase_array(elements)
      new_elements.first.should eql("hallo")
      new_elements.last.should eql("bamboo")
    end
  end

  # TODO refactor this for the new license model
  # describe "handling product licenses" do
  #   it "- get licence of product, that is added by crawler" do
  #     p = described_class.new name: "Testdescribed_class", license: "Apache22"
  #     p.license_info.should eql("Apache22")
  #   end

  #   it "- get license of product that is added by user" do
  #     p = described_class.new name: "testdescribed_class2", license_manual: "Rocket42"
  #     p.license_info.should eql("Rocket42")
  #   end
  # end

  describe "get_unique_languages_for_product_ids" do

    it "returns unique languages for the product" do
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      product_3 = ProductFactory.create_new 3, Project::A_TYPE_COMPOSER
      languages = described_class.get_unique_languages_for_product_ids( [product_1.id, product_2.id, product_3.id] )
      languages.size.should eq(2)
      languages.include?("PHP").should be_true
      languages.include?("Java").should be_true
    end

  end

end
