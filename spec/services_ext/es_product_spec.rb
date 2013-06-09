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
    EsProduct.clean_all #remove all previous indexes at elasticsearch
    EsProduct.create_index_with_mappings
    @prods = [
      {:name => "club-mate",        :language => "Java", :group_id => "org.club.mate"},
      {:name => "club-mate-parent", :language => "Java", :group_id => "com.club.mate"},
      {:name => "club-mate-child",  :language => "Java", :group_id => "net.club.mate"},
      {:name => "club-mate-c",      :language => "C",    :group_id => ""},
      {:name => "club-mate-ccc",    :language => "c++",  :group_id => ""},
      {:name => "club-mate-ruby",   :language => "Ruby", :group_id => ""},
      {:name => "club-mate-cnet",   :language => "c#",   :group_id => "net.microsoft.crap"},
      {:name => "bad.mate.jar",     :language => "mate", :group_id => "club.mate.org"},
      {:name => "good.mate.jar",    :language => "mate", :group_id => "club.mate.org"},
      {:name => "superb_mate.jar",  :language => "mate", :group_id => "club.mate.org"}
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

  after :each do
    EsProduct.clean_all
    Product.where().delete
  end

  context "With no indexes: " do

    it "does clean_all successfull" do
      begin
        EsProduct.clean_all # clean all previous accidental data
        # if elasticsearch is empty, then it should return false
        EsProduct.clean_all
        "true".should eql("false")
      rescue
        "true".should eql("true")
      end
    end

    it "is nil because no index" do
      begin
        EsProduct.search("random query")
        "true".should eql("false")
      rescue
        "true".should eql("true")
      end
    end

  end


  context "Only one product in Index." do

    it "adds one element to the index" do
      product = @products[0]
      result = EsProduct.index product
      result.response.code.should eql(200)
    end

    it "Finds the only element in the index by name" do
      EsProduct.clean_all
      product = Product.new(:name => "rails")
      product.save
      EsProduct.index product
      sleep 2 # sleep for 2 seconds until the product gets indexed via REST.
      results = EsProduct.search "rails"
      results.count.should eql(1)
    end

  end


  context "Club-Mate in the house" do
    it "Finds club-mate first!" do
      results = EsProduct.search "club-mate"
      results.count.should eql(7)
      results[0].name.should eql("club-mate") #async adding&indexing gaves diff results
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

    # TODO: c gaves every c language, but c++ and c# dont work at all
    # Right now this case is not important because we are not tracking c++ or c#
    it "test language filtering"  do
      sleep 4
      EsProduct.search("club-mate", nil, ["Java"]).count.should eql(3)
    end

    # it "test, does language filtering is case insensitive" do
    #   sleep 4
    #   results1 = EsProduct.search "club-mate", nil, ["Java"]
    #   results2 = EsProduct.search "club-mate", nil, ["java"]
    #   results1[0][:name].should eql results2[0][:name]
    #   results1.count.should eql(results2.count)
    # end

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

    it "Give only exact matches and nothing else." do
      sleep  4
      EsProduct.search_exact("club-mate").count.should eql(1)
      EsProduct.search_exact("club-mate-c").count.should eql(1)
      EsProduct.search_exact("club-mate-child").count.should eql(1)
    end
  end

end
