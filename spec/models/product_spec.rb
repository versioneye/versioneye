require 'spec_helper'

describe Product do

  let( :product ) { Product.new(:language => Product::A_LANGUAGE_RUBY, :prod_key => "funny_bunny", :version => "1.0.0") }
  let(:version1) {FactoryGirl.build(:product_version, version: "0.0.1")}
  let(:version2) {FactoryGirl.build(:product_version, version: "0.0.2")}
  let(:version3) {FactoryGirl.build(:product_version, version: "0.1")}

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
      link = Versionlink.new({language: product.language, prod_key: product.prod_key})
      link.link = "http://link.de"
      link.name = "Name"
      link.save.should be_true
      db_link = Versionlink.find(link.id)
      db_link.should_not be_nil
      links = product.http_links
      links.size.should eq(1)
      link.remove
    end

    it "returns an empty array" do
      link = Versionlink.new
      link.language = product.language
      link.prod_key = product.prod_key
      link.link = "http://link.de"
      link.version = "nope"
      link.name = "Name"
      link.save
      product.http_links.size.should eq(0)
      link.remove
    end

    it "returns 1 link" do
      link = Versionlink.new({language: product.language, prod_key: product.prod_key})
      link.link = "http://link.de"
      link.version = "1.1"
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

  describe "handling product licenses" do
    it "- get licence of product, that is added by crawler" do
      product1 = ProductFactory.create_for_gemfile("bee", "1.4.0")
      product1.versions.push( Version.new({version: "1.4.0"}) )
      product1.save
      license = License.new({:language => product1.language, :prod_key => product1.prod_key,
        :version => product1.version, :name => "MIT"})
      license.save
      product1.license_info.should eql("MIT")
      license = License.new({:language => product1.language, :prod_key => product1.prod_key,
        :version => product1.version, :name => "GLP"})
      license.save
      product1.license_info.should eql("MIT, GLP")
    end
  end

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

  describe "version_by_number" do
    it "returns nil when number is nil" do
      product.version_by_number(nil).should be_nil
    end

    it "returns nil when product has no versions" do
      product.version_by_number("1.0.0").should be_nil
    end

    it "returns nil when prodoct has no matching versions" do
      product.versions << version1
      product.versions << version2
      product.save
      product.version_by_number("1.0.0").should be_nil
    end

    it "returns correct version when there's matching version" do
      product.versions.delete_all
      product.versions << version1
      product.versions << version2
      product.save
      product.version_by_number("0.0.1").should_not be_nil
    end

    it "should find correct version when there's massive set of subdoc" do
        product.versions.delete_all
        40.times do |i|
          product.versions << FactoryGirl.build(:product_version, version: "0.#{i}.1")
        end
        product.save

        match = product.version_by_number("0.12.1")
        match.should_not be_nil
        match[:version].should eql("0.12.1")
    end

    it "should find correct version even there may be versions with invalid or missing value" do
      product.versions.delete_all
      product.versions << version1
      product.versions << FactoryGirl.build(:product_version, version: nil)
      product.versions << FactoryGirl.build(:product_version, version: "")
      product.versions << FactoryGirl.build(:product_version, version: 1)
      product.versions << FactoryGirl.build(:product_version, version: 1.0)
      product.versions << FactoryGirl.build(:product_version, version: 1.minutes.ago)
      product.versions << version2
      product.save

      match = product.version_by_number(version2[:version])
      match.should_not be_nil
      match[:version].should eql(version2[:version])
    end
  end


  describe "update_used_by_count" do

    it "returns 0 because there are no deps" do
      product_1 = ProductFactory.create_new 1
      product_1.save
      product_1.update_used_by_count
      product_1.used_by_count.should eq(0)
    end

    it "returns 1 because there is 1 dep" do
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      dependency = Dependency.new({ :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => product_2.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency.save
      product_1.save
      product_1.update_used_by_count
      product_1.used_by_count.should eq(1)
    end

    it "returns still 1 because there are 2 deps from 1 product" do
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      dependency = Dependency.new({ :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => product_2.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency.save
      dependency2 = Dependency.new({ :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => "dev-master",
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency2.save
      product_1.save
      product_1.update_used_by_count
      product_1.used_by_count.should eq(1)
    end

    it "returns 2 because there are 2 deps" do
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      product_3 = ProductFactory.create_new 3
      dependency = Dependency.new({ :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => product_2.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency.save
      dependency2 = Dependency.new({ :language => product_3.language,
        :prod_key => product_3.prod_key, :prod_version => product_3.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency2.save
      product_1.save
      product_1.update_used_by_count
      product_1.used_by_count.should eq(2)
    end

  end

  describe 'check_nil_version' do

    it 'returns nil' do
      product = Product.new
      product.check_nil_version
      product.version.should be_nil
    end

    it 'returns 1.0.0' do
      product = Product.new
      product.versions.push(Version.new({:version => '1.0.0'}))
      product.check_nil_version
      product.version.should eq('1.0.0')
    end

    it 'returns 2.0.0' do
      product = Product.new({:version => '2.0.0'})
      product.check_nil_version
      product.version.should eq('2.0.0')
    end

  end

end
