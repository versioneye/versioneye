require 'spec_helper'

describe Product do

  let( :product ) { Product.new }

  describe "find_by" do

    it "returns an empty list. Search term is not in the DB" do
      name = "junitggasgagasgj8623"
      product.name = name
      product.name_downcase = name
      product.prod_key = "gasgagasgj8623_junit/junit"
      product.save
      results = described_class.find_by( "sgj8623agajklnb8738gas", nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(0)
    end

    it "returns an empty list. Search term is an empty string" do
      name = "junitggasgagasgj8623"
      product.name = name
      product.name_downcase = name
      product.prod_key = "gasgagasgj8623_junit/junit"
      product.save
      results = described_class.find_by( "", nil, nil, nil, 300 )
      results.should_not be_nil
      results.size.should eq(0)
    end

    it "returns an empty list. Search term is nil" do
      name = "junitggasgagasgj8623"
      product.name = name
      product.name_downcase = name
      product.prod_key = "gasgagasgj8623_junit/junit"
      product.save
      results = described_class.find_by( nil, nil, nil, nil, 300 )
      results.should_not be_nil
      results.size.should eq(0)
    end

    it "returns the searhced product. Simple case. Exact macht!" do
      name = "junitggasgagasgj8623"
      product.name = name
      product.name_downcase = name
      product.prod_key = "gasgagasgj8623_junit/junit"
      product.save
      results = described_class.find_by( name, nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(1)
    end

    it "returns the searhced product. Upper Case. Exact macht with caseinsensitive!" do
      name = "junitggasgagasgj8623"
      product.name = name
      product.name_downcase = name
      product.prod_key = "gasgagasgj8623_junit/junit"
      product.save
      results = described_class.find_by( name, nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(1)
    end

    it "returns the searhced product. Part of the Name - first digits." do
      name = "junitggasgagasgj8623"
      product.name = name
      product.name_downcase = name
      product.prod_key = "gasgagasgj8623_junit/junit"
      product.save
      results = described_class.find_by( "junitggasg", nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(1)
    end

    it "returns the searhced product. Part of the Name - last digits." do
      name = "junitggasgagasgj8623"
      product.name = name
      product.name_downcase = name
      product.prod_key = "gasgagasgj8623_junit/junit"
      product.save
      results = described_class.find_by( "sgj8623", nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(1)
    end

    it "returns the searhced product. Part of the Name - last digits." do
      name = "hiberante-core"
      product.name = name
      product.name_downcase = name
      product.prod_key = "org/hibernate-core"
      product.save
      results = described_class.find_by( "hiberante-core", nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(1)
    end

    it "returns the searhced product. Part of the Name - middle digits." do
      name = "junitggasgagasgj8623"
      product.name = name
      product.name_downcase = name
      product.prod_key = "gasgagasgj8623_junit/junit"
      product.save
      results = described_class.find_by( "tggasgagasgj86", nil, nil, nil, 300 )
      results.should_not be_nil
      results.size.should eq(1)
    end

    it "returns the searhced product because searched_name is in description" do
      name = "asgfasfgasgasfgs"
      product.name = name
      product.name_downcase = name
      product.prod_key = "gasgagasgj8623_junit/junitagasfgas"
      product.description = "this is BuBuBo. OK?"
      product.save
      results = described_class.find_by( nil, "BuBuBo", nil, nil, 300 )
      results.should_not be_nil
      results.size.should eq(1)
    end

    it "returns the searhced product because searched_name is in description_manual" do
      name = "asgfasfgasgasfgs23"
      product.name = name
      product.name_downcase = name
      product.prod_key = "gasgagasgj8623_junit/junitagasfgas"
      product.description_manual = "this is BuBuBoHapo gasgfs"
      product.save
      results = described_class.find_by(nil, "BuBuBoHapo", nil, nil, 300 )
      results.should_not be_nil
      results.size.should eq(1)
    end

    it "returns searhced products. Combination of start and simple" do
      name = "start_not_apple"
      product.name = name
      product.name_downcase = name
      product.prod_key = "apple_bike_pie/unit"
      product.save

      product = described_class.new
      product.versions = Array.new
      product.name = "apple_start_with"
      product.name_downcase = "apple_start_with"
      product.prod_key = "apple_bike_pie12/unit"
      product.save

      results = described_class.find_by( "apple", nil, nil, nil, 300  )
      results.should_not be_nil
      results.size.should eq(2)

      product.remove
    end

    it "returns just java, because lang filter is on" do
      product1 = ProductFactory.create_for_gemfile("bee", "1.4.0")
      product1.versions.push( Version.new({version: "1.3.0"}) )
      product1.save

      product2 = ProductFactory.create_for_maven("bumble", "bee", "1.4.0")
      product2.versions.push( Version.new({version: "1.3.0"}) )
      product2.save

      results = described_class.find_by( "bee", nil, nil, ["Java"], 300  )
      results.should_not be_nil
      results.size.should eq(1)
      results[0].language.should eql("Java")

      product1.remove
      product2.remove
    end

    it "returns just ruby, because lang filter is on" do
      product1 = ProductFactory.create_for_gemfile("bee", "1.4.0")
      product1.versions.push( Version.new({version: "1.3.0"}) )
      product1.save

      product2 = ProductFactory.create_for_maven("bumble", "bee", "1.4.0")
      product2.versions.push( Version.new({version: "1.3.0"}) )
      product2.save

      results = described_class.find_by( "bee", nil, nil, ["Ruby"], 300  )
      results.should_not be_nil
      results.size.should eq(1)
      results[0].language.should eql("Ruby")

      product1.remove
      product2.remove
    end

    it "returns java and ruby, because lang filter is on" do
      product1 = ProductFactory.create_for_gemfile("bee", "1.4.0")
      product1.versions.push( Version.new({version: "1.3.0"}) )
      product1.save

      product2 = ProductFactory.create_for_maven("bumble", "bee", "1.4.0")
      product2.versions.push( Version.new({version: "1.3.0"}) )
      product2.save

      results = described_class.find_by( "bee", nil, nil, ["Ruby", "Java"], 300  )
      results.should_not be_nil
      results.size.should eq(2)

      product1.remove
      product2.remove
    end

  end

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

  describe "handling product licenses" do
    it "- get licence of product, that is added by crawler" do
      p = described_class.new name: "Testdescribed_class", license: "Apache22"
      p.license_info.should eql("Apache22")
    end

    it "- get license of product that is added by user" do
      p = described_class.new name: "testdescribed_class2", license_manual: "Rocket42"
      p.license_info.should eql("Rocket42")
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

end
