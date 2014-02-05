require 'spec_helper'

def add_local_products
  @prods.each do |prod|
    product = Product.new prod
  end
end

def get_index_count
  response = RestClient.get("http://localhost:9200/product_test/_count")
  JSON.parse(response)["count"]
end

describe EsProduct do

  before :each do
    EsProduct.reset
    @prods = [
      {:name => "club-mate",        :prod_key => "club-mate",         :prod_type => 'Maven'   , :language => "Java",    :group_id => "org.club.mate", :followers => 1, :used_by_count => 1},
      {:name => "club-mate-parent", :prod_key => "club-mate-parent",  :prod_type => 'Maven'   , :language => "Java",    :group_id => "com.club.mate", :followers => 1, :used_by_count => 1},
      {:name => "club-mate-child",  :prod_key => "club-mate-child",   :prod_type => 'Maven'   , :language => "Java",    :group_id => "net.club.mate", :followers => 1, :used_by_count => 1},
      {:name => "club-mate-c",      :prod_key => "club-mate-c",       :prod_type => 'GitHub'  , :language => "C",       :group_id => ""             , :followers => 1, :used_by_count => 1},
      {:name => "club-mate-ccc",    :prod_key => "club-mate-ccc",     :prod_type => 'GitHub'  , :language => "c++",     :group_id => ""             , :followers => 1, :used_by_count => 1},
      {:name => "club-mate-ruby",   :prod_key => "club-mate-ruby",    :prod_type => 'RubyGems', :language => "Ruby",    :group_id => ""             , :followers => 1, :used_by_count => 1},
      {:name => "club-mate-cnet",   :prod_key => "club-mate-cnet",    :prod_type => 'GitHub'  , :language => "c#",      :group_id => "net.msoft.rap", :followers => 1, :used_by_count => 1},
      {:name => "bad.mate.jar",     :prod_key => "bad.mate.jar",      :prod_type => 'Maven'   , :language => "mate",    :group_id => "club.mate.org", :followers => 1, :used_by_count => 1},
      {:name => "good.mate.jar",    :prod_key => "good.mate.jar",     :prod_type => 'Maven'   , :language => "mate",    :group_id => "club.mate.org", :followers => 1, :used_by_count => 1},
      {:name => "superb_mate.jar",  :prod_key => "superb_mate.jar",   :prod_type => 'Maven'   , :language => "mate",    :group_id => "club.mate.org", :followers => 1, :used_by_count => 1},
      {:name => "json_nodejs",      :prod_key => "json_nodejs",       :prod_type => 'NPM'     , :language => "Node.JS", :group_id => ""             , :followers => 1, :used_by_count => 1},
      {:name => "Hibernate",        :prod_key => "Hibernate",         :prod_type => 'Maven'   , :language => "Java",    :group_id => "org.hibernate", :followers => 1, :used_by_count => 1}
    ]
    @products = Array.new
    @prods.each do |prod|
      product = Product.new(prod)
      product.save
      EsProduct.index product
      @products.push product
    end
    sleep 3
  end

  context "With no indexes: " do

    it "does clean_all successfull" do
      EsProduct.clean_all.should be_true
      EsProduct.clean_all.should be_false
    end

    it "empty result because no index" do
      results = EsProduct.search("random query")
      results.should be_empty
    end

  end


  context "Only one product in Index." do

    it "adds one element to the index" do
      product = @products[0]
      result = EsProduct.index product
      result.response.code.should eql(200)
    end

    it "Finds the only element in the index by name" do
      EsProduct.reset
      product = Product.new(:name => "rails", :prod_type => 'RubyGems', :language => 'Ruby', :prod_key => 'rails')
      product.save.should be_true
      EsProduct.index product
      sleep 3 # sleep for 2 seconds until the product gets indexed via REST.
      results = EsProduct.search "rails"
      results.count.should eql(1)
    end

  end


  context "Club-Mate in the house" do
    it "Finds club-mate first!" do
      results = EsProduct.search "club-mate"
      results.count.should eql(7)
      results[0].name.should eql("club-mate")
    end
  end


  context "- index only documents, which has flagged to reindex" do
    it "index_newest" do
      EsProduct.clean_all
      @products.each do |product|
        product.update_attribute(:reindex, true)
      end
      EsProduct.index_newest
      get_index_count.should equal @products.count

      Product.where(reindex: true).count.should equal 0
    end
  end

  context " - index all documents in `products` collection" do
    it "index_all" do
      EsProduct.clean_all
      EsProduct.create_index_with_mappings
      sleep 4
      add_local_products
      EsProduct.index_all
      sleep 4
      get_index_count.should eql(Product.count)
    end
  end


  context "- tests search functionalities " do

    it "search empty string should rais exception" do
      EsProduct.index_all
      expect { EsProduct.search("") }.to raise_error(ArgumentError)
    end

    it "test language filtering"  do
      sleep 4
      EsProduct.search("club-mate", nil, ["Java"]).count.should eql(3)
    end

    it "test language filtering does decodes language name correctly"  do
      sleep 4
      EsProduct.search("json_nodejs", nil, ["nodejs"]).count.should eql(1)
    end

    it " - should return 1 result with the right group_id." do
      sleep 5
      results = EsProduct.search nil, "com."
      results.count.should eql(1)
      results[0].group_id.should eql("com.club.mate")
    end

    it "test filtering by group-id" do
      sleep 4
      results = EsProduct.search "mate", "org."
      results.count.should eql(1)
      results[0][:group_id].should eql "org.club.mate"
    end

    it "test finding names, which includes points" do
      sleep 4
      results = EsProduct.search "bad.mate.jar"
      results.count.should eql(1)
    end

    it "test finding names, which includes underscores" do
      sleep 5
      results = EsProduct.search "superb_mate.jar"
      results.count.should eql(1)
    end

    it "returns Hibernate because of perect match" do
      results = EsProduct.search "Hibernate"
      results.count.should eql(1)
      results.first.name.should eql("Hibernate")
    end

    it "returns Hibernate" do
      results = EsProduct.search "hibernat"
      results.count.should eql(1)
      results.first.name.should eql("Hibernate")
    end

  end

end
