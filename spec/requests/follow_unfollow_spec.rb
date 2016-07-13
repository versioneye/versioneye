require 'spec_helper'

describe "follow and unfollow" do

  let(:prod_key){ "json_goba" }
  let(:prod_lang){ Product::A_LANGUAGE_RUBY }
  let(:version){"1.0"}
  let(:user){ FactoryGirl.create(:default_user) }

  def init_product
    product = Product.new
    product.versions      = Array.new
    product.name          = prod_key
    product.name_downcase = prod_key
    product.prod_key      = prod_key
    product.prod_type     = "RubyGem"
    product.language      = Product::A_LANGUAGE_RUBY
    product.version       = "1.0"
    product.save.should be_truthy
    version               = Version.new
    version.version       = "1.0"
    product.versions.push(version)
    product
  end

  context "logged out" do
    it "fetches product page successfully" do
      init_product
      p Product.count
      p Product.first.to_s

      Rails.cache.clear
      LanguageService.cache.delete "distinct_languages"

      begin
        get "/#{prod_lang}/#{prod_key}/#{version}"
      rescue => e
        p e.message
        p e.backtrace.messages.join(" - ")
      end
      assert_response :success
      assert_select "button[class=?]", "btn btn-large btn-primary"
    end
  end

  context "logged in" do

    before :each do
      Rails.cache.clear
      LanguageService.cache.delete "distinct_languages"

      post "/sessions", {:session => {:email => user.email, :password => user.password}}, "HTTPS" => "on"
      assert_response 302
      response.should redirect_to( projects_organisation_path( Organisation.first ) )
    end

    it "does follow successfully" do
      init_product
      post "/package/follow", :product_key => prod_key, :product_lang => prod_lang
      assert_response 302
      response.should redirect_to( "/#{prod_lang.downcase}/#{prod_key}/#{version}" )
      response.body.should_not match( "An error occured" )

      prod = Product.fetch_product( prod_lang, prod_key )
      subscribers = prod.users
      subscribers.size.should eq(1)
      subscribers.first.email.should eql( user.email )

      get "/ruby/json_goba/1.0"
      assert_select "button[class=?]", "btn btn-large"
      response.body.should match(prod_key)
    end

    it "fetches the i follow page successfully" do
      init_product
      post "/package/follow", :product_key => prod_key, :product_lang => prod_lang
      get user_packages_i_follow_path
      assert_response :success
      assert_select "div[class=?]", "row search-item"
      response.body.should match(prod_key)
    end

    it "unfollows successfully" do
      init_product
      post "/package/follow",   :product_key => prod_key, :product_lang => prod_lang
      post "/package/unfollow", :product_key => prod_key, :product_lang => prod_lang, :src_hidden => "detail"
      assert_response 302
      response.should redirect_to( "/#{prod_lang.downcase}/#{prod_key}/#{version}" )

      get "/ruby/json_goba/1.0"
      # assert_select :tag => "button", :attributes => { :class => "btn btn-large btn-primary", :type => "submit" }
      assert_select "button[class=?]", "btn btn-large btn-primary"
      response.body.should match(prod_key)

      prod = Product.fetch_product( prod_lang, prod_key )
      subscribers = prod.users
      subscribers.size.should eq(0)
    end

  end

end
