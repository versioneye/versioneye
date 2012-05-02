require 'spec_helper'

describe "search" do

  it "show detail page for a package" do 
  	product = Product.new
  	product.versions = Array.new
    product.name = "json"
    product.prod_key = "json"
    product.prod_type = "RubyGem"
    product.language = "Ruby"
    product.version = "1.0"
    product.rate = 50
    version = Version.new
    version.version = "1.0"
    product.versions.push(version)
    product.save

    results = Product.find_by_name( "json" )
    results.should_not be_nil
    results.size.should eq(1)

    get "/package/json"
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"
    
    assert_tag :tag => "section", :attributes => { :class => "round"}
    assert_tag :tag => "div", :attributes => { :class => "content"}
    assert_tag :tag => "ul", :attributes => { :class => "list-row product_header"}

    product.remove
  end
end