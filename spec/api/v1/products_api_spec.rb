require 'spec_helper'


describe ProductsApiV1 do

  let( :product_uri ) { "/api/v1/products" }
  let(:prod1){FactoryGirl.build(:product, 
                                  prod_key: "product1",
                                  name: "product1",
                                  version: '1.0.0'
                                  )}

  before :each do
    prod1.save
    FakeWeb.allow_net_connect = true
  end

  after :each do
    Product.delete_all
  end

  def encode_prod_key(prod_key)
    prod_key.gsub("/", ":")
  end

  def fill_db_with_products
    EsProduct.reset
    test_products = []
    55.times do |i| 
      prod = FactoryGirl.create(:product,
                               prod_key: "product#{i}",
                               name: "product#{i}",
                               language: "Ruby",
                               version: '1.0.#{i}')
      prod.save
    end
    EsProduct.index_all
  end


  describe "GET detailed info for specific packcage" do
    it "returns same product" do
      prod_key_safe = encode_prod_key( prod1.prod_key )
      package_url =  "#{product_uri}/#{prod_key_safe}.json"
      get package_url
      response.status.should eql(200)
      response_data = JSON.parse(response.body)
      response_data["name"].should eql( prod1[:name] )
    end
  end


  describe "Search packages" do
    it "returns statuscode 400, when search query is too short or missing " do
      get "#{product_uri}/search/1.json"
      response.status.should eql(400)
    end

    it "returns status 200 and search results with correct parameters" do
      Product.delete_all
      search_term = fill_db_with_products
      Product.count.should eq(55)
      get "#{product_uri}/search/produ*.json"
      response.status.should eql(200)
      response_data = JSON.parse(response.body)
      response_data['results'][0]["name"].should =~ /product/i
    end

    it "returns other paging when user specifies page parameter" do
      fill_db_with_products
      get "#{product_uri}/search/produ*.json", :page => 2
      response.status.should eql(200)
      response_data = JSON.parse(response.body)
      response_data['paging']["current_page"].should == 2
    end

    it "returns first page, when page argument is zero or less " do
      fill_db_with_products
      get "#{product_uri}/search/produ*.json", :page => 0
      response.status.should == 200
      response_data  = JSON.parse(response.body)
      response_data['paging']["current_page"].should == 1
    end
  end


  describe "unauthorized user tries to use follow" do
    it "returns unauthorized error, when lulsec tries to get follow status" do
      test_product  = ProductFactory.create_new 101
      safe_prod_key = encode_prod_key(test_product.prod_key)
      get "#{product_uri}/#{safe_prod_key}/follow"
      response.status.should == 401
    end

    it "returns unauthorized error, when lulsec tries to follow package" do
      test_product  = ProductFactory.create_new 101
      safe_prod_key = encode_prod_key(test_product.prod_key)
      post "#{product_uri}/#{safe_prod_key}/follow"
      response.status.should == 401
    end

    it "returns unauthorized error, when lulSec tries to unfollow"  do
      test_product  = ProductFactory.create_new 101
      safe_prod_key = encode_prod_key(test_product.prod_key)
      delete "#{product_uri}/#{safe_prod_key}/follow"
      response.status.should == 401
    end
  end


  describe "authorized user tries to use follow" do
    before(:each) do
      @test_product = ProductFactory.create_new 102
      @test_user = UserFactory.create_new
      @user_api = ApiFactory.create_new @test_user
      @safe_prod_key = encode_prod_key(@test_product.prod_key)

      #initialize new session
      post '/api/v1/sessions', :api_key => @user_api.api_key
    end

    it "checking state of follow should be successful" do
      get "#{product_uri}/#{@safe_prod_key}/follow"
      response.status.should == 200
      response_data =  JSON.parse(response.body)
      response_data["prod_key"].should eql(@test_product.prod_key)
      response_data["follows"].should be_false
    end

    it "returns success if authorized user follows specific package" do
      post "#{product_uri}/#{@safe_prod_key}/follow"
      response.status.should == 201
      response_data =  JSON.parse(response.body)
      response_data["prod_key"].should eql(@test_product.prod_key)
      response_data["follows"].should be_true
    end

    it "returns proper response if authorized unfollows specific package" do
      delete "#{product_uri}/#{@safe_prod_key}/follow"
      response.status.should == 200

      get "#{product_uri}/#{@safe_prod_key}/follow"
      response_data = JSON.parse(response.body)
      response_data["follows"].should be_false
    end
  end


  describe "accessing follow with instantaneous authorization" do
    before(:each) do
      @test_user = UserFactory.create_new 10
      @test_product = ProductFactory.create_new 103
      @user_api = ApiFactory.create_new @test_user
      @safe_prod_key = encode_prod_key(@test_product.prod_key)
    end

    it "fails when user skips authorization key" do
      get "#{product_uri}/#{@safe_prod_key}/follow"
      response.status.should == 401
      delete "/api/v1/sessions"
    end

    it "returns success if user, who's not authorized yet, tries to check follow" do
      get "#{product_uri}/#{@safe_prod_key}/follow", :api_key => @user_api.api_key
      response.status.should == 200
      delete "/api/v1/sessions"
    end
  end

end
