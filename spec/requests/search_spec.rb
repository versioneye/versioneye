require 'spec_helper'

describe "search" do
  it "shows the default search" do
    post "/search", :q => ""
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"
    assert_select "body div.container section"
    assert_select "div#searchresults"
  end

  it "show the search with 1 result" do 
  	product = Product.new
  	product.versions = Array.new
    product.name = "json"
    product.prod_key = "json/json"
    product.rate = 50
    product.save
    version = Version.new
    version.version = "1.0"
    product.versions.push(version)
    product.save

    results = Product.find_by_name( "json" )
    results.should_not be_nil
    results.size.should eq(1)

    post "/search", :q => "json"
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"
    assert_select "body div.container section"
    assert_select "div#searchresults"
    assert_tag :tag => "div", :attributes => { :class => "searchResults"}, :children => {:count => 1..2}
    assert_tag :tag => "div", :attributes => { :class => "searchResult"}, :parent => { :tag => "div" }
    assert_tag :tag => "a", :attributes => { :class => "searchResultLink"}

    product.remove
  end
end