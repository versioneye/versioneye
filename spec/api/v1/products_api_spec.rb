require 'spec_helper'

describe VersionEye::ProductsApi do
  describe "GET detailed info for specific packcage" do
    before(:each) do
      @test_product = ProductFactory.create_new
    end

    after(:each) do
      @test_product.delete
    end

    it "returns same product" do
      prod_key_safe = @test_product.prod_key.gsub("/", "--").gsub(".", "~")
      package_url =  "/v1/products/#{prod_key_safe}.json"
      p package_url
      get package_url
      response.status.should eql(200)
      response_data = JSON.parse(response.body)
      response_data["name"].should eql(@test_product.name)
    end
  end


  describe "Search packages" do
    before(:each) do
      @test_products = []
      5.times {|i| @test_products << ProductFactory.create_new(i)}
    end

    after(:each) do
      @test_products.each {|item| item.delete}
    end

    it "returns statuscode 400, when search query is too short or missing " do
      get "/v1/products/search/1.json"
      response.status.should eql(400)
    end

    it "returns status 200 and search results with correct parameters" do
      search_term = @test_products[0].name.chop.chop
      get "/v1/products/search/#{search_term}.json"
      response.status.should eql(200)
      response_data = JSON.parse(response.body)
      response_data[0]["name"].should =~ /test_class/
    end
  end
end
