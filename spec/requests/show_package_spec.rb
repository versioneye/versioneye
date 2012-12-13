require 'spec_helper'

describe "search" do

  it "show detail page for a package" do 
  	product = Product.new
  	product.versions = Array.new
    product.name = "json"
    product.name_downcase = "json"
    product.prod_key = "json"
    product.prod_type = "RubyGem"
    product.language = "Ruby"
    product.version = "1.0"
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
    
    assert_tag :tag => "section", :attributes => { :class => "container"}
    assert_tag :tag => "ul", :attributes => { :class => "nav pull-right"}

    product.remove
  end

  it "show visual page for a package" do 
    product = Product.new
    product.versions = Array.new
    product.name = "json_g"
    product.name_downcase = "json_g"
    product.prod_key = "json_g"
    product.prod_type = "RubyGem"
    product.language = "Ruby"
    product.version = "1.0"
    version = Version.new
    version.version = "1.0"
    product.versions.push(version)
    product.save

    results = Product.find_by_name( "json_g" )
    results.should_not be_nil
    results.size.should eq(1)

    get "/package_visual/json_g/version/1~0"
    assert_response :success
    # assert_select "form[action=?]", "/search"
    # assert_select "input[name=?]", "q"
    
    assert_tag :tag => "h1", :attributes => { :style => "margin-bottom: 5px;"}

    product.remove
  end

end