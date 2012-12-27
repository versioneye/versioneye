require 'spec_helper'

describe "search" do
  
  it "shows the default search" do
    get "/search", :q => ""
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"
    assert_select "div#search-results"
  end

  it "show the search with 1 result" do 
  	product = Product.new
  	product.versions = Array.new
    product.name = "json"
    product.name_downcase = "json"
    product.prod_key = "json/json"
    product.language = "Java"
    product.save
    version = Version.new
    version.version = "1.0"
    product.versions.push(version)
    product.save

    results = Product.find_by_name( "json" )
    results.should_not be_nil
    results.size.should eq(1)

    get "/search", :q => "json"
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"
    assert_select "div#search-results"
    assert_tag :tag => "div", :attributes => { :class => "row search-item"}, :parent => { :tag => "div" }
    assert_tag :tag => "a", :attributes => { :class => "searchResultLink"}

    product.remove
  end

  it "shows the search with 2 result" do 
    product = Product.new
    product.versions = Array.new
    product.name = "junit"
    product.name_downcase = "junit"
    product.prod_key = "junit/junit"
    product.language = "Java"
    product.save
    version = Version.new
    version.version = "1.0"
    product.versions.push(version)
    product.save

    product2 = Product.new
    product2.versions = Array.new
    product2.name = "junitHP"
    product2.name_downcase = "junithp"
    product2.prod_key = "junit/junithp"
    product2.language = "Java"
    product2.save
    version2 = Version.new
    version2.version = "1.0"
    product2.versions.push(version2)
    product2.save

    results = Product.find_by_name( "junit" )
    results.should_not be_nil
    results.size.should eq(2)

    get "/search", :q => "junit"
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"
    assert_select "div#search-results"
    assert_tag :tag => "input", :attributes => { :id => "q", :name => "q", :value => "junit", :type => "text" }
    assert_tag :tag => "div", :attributes => { :class => "row search-item"}, :parent => { :tag => "div" }
    assert_tag :tag => "a", :attributes => { :class => "searchResultLink"}

    product.remove
    product2.remove
  end

end