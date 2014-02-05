require 'spec_helper'

describe MongoProduct do

  let( :product ) { Product.new({:language => 'Ruby', :prod_type => 'RubyGems'}) }

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

    it "returns searhced products. Combination of start and simple" do
      name = "start_not_apple"
      product.name = name
      product.name_downcase = name
      product.prod_key = "apple_bike_pie/unit"
      product.save

      product = Product.new({:language => 'Ruby', :prod_type => 'RubyGems'})
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

end
