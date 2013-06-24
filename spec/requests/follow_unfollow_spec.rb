require 'spec_helper'

describe "follow and unfollow" do

  let(:prod_key){ "json_goba" }
  let(:user){ FactoryGirl.create(:default_user) }

  def init_product
    product = Product.new
    product.versions = Array.new
    product.name = prod_key
    product.name_downcase = prod_key
    product.prod_key = prod_key
    product.prod_type = "RubyGem"
    product.language = "Ruby"
    product.version = "1.0"
    version = Version.new
    version.version = "1.0"
    product.versions.push(version)
    product.save
    product
  end

  context "logged out" do
    it "fetches product page successfully" do
      init_product
      get "/package/#{prod_key}"
      assert_response :success
      assert_tag :tag => "button", :attributes => { :class => "btn2 btn2-big", :type => "submit" }
    end
  end

  context "logged in" do

    before :each do
      post "/sessions", {:session => {:email => user.email, :password => user.password}}, "HTTPS" => "on"
      assert_response 302
      response.should redirect_to( new_user_project_path )
    end

    it "does follow successfully" do
      init_product
      post "/package/follow", :product_key => prod_key
      assert_response 302
      response.should redirect_to( "/package/#{prod_key}" )
      response.body.should_not match( "An error occured" )

      prod = Product.find_by_key( prod_key )
      subscribers = prod.users
      subscribers.size.should eq(1)
      subscribers.first.email.should eql( user.email )

      get "/package/json_goba/1.0"
      assert_tag :tag => "button", :attributes => { :class => "btn2 btn-large btn-warning", :type => "submit" }
      response.body.should match("1 Followers")
    end

    it "fetches the i follow page successfully" do
      init_product
      post "/package/follow", :product_key => prod_key
      get user_packages_i_follow_path
      assert_response :success
      assert_tag :tag => "div", :attributes => { :class => "row search-item" }
      response.body.should match(prod_key)
    end

    it "unfollows successfully" do
      init_product
      post "/package/follow",   :product_key => prod_key
      post "/package/unfollow", :product_key => prod_key, :src_hidden => "detail"
      assert_response 302
      response.should redirect_to("/package/#{prod_key}")

      get "/package/json_goba/1.0"
      assert_tag :tag => "button", :attributes => { :class => "btn btn-large btn-success", :type => "submit" }
      response.body.should match("0 Followers")

      prod = Product.find_by_key( prod_key )
      subscribers = prod.users
      subscribers.size.should eq(0)
    end

  end

end
