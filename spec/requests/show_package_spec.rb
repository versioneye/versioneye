require 'spec_helper'

describe "show_package_controller" do

  it "show detail page for a package" do
    product = Product.new({:name => "json", :name_downcase => "json",
      :prod_key => "json", :prod_type => "RubyGem", :version => "1.0",
      :language => Product::A_LANGUAGE_RUBY})
    product.save
    product.versions.push( Version.new({:version => "1.0"}) )

    results = MongoProduct.find_by_name( "json" )
    results.should_not be_nil
    results.size.should eq(1)

    Rails.cache.clear
    LanguageService.cache.delete "distinct_languages"

    get "/ruby/json/1.0"
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"

    assert_tag :tag => "section", :attributes => { :class => "container"}

    product.remove
  end

  it "show visual page for a package" do
    product = Product.new({:name => "json_g", :name_downcase => "json_g",
      :prod_key => "json_g", :prod_type => "RubyGem", :version => "1.0",
      :language => Product::A_LANGUAGE_RUBY})
    product.save
    product.versions.push Version.new({:version => "1.0"})

    results = MongoProduct.find_by_name( "json_g" )
    results.should_not be_nil
    results.size.should eq(1)

    Rails.cache.clear
    LanguageService.cache.delete "distinct_languages"

    get "/ruby/json_g/1.0/visual_dependencies"
    assert_response :success

    assert_tag :tag => "h1", :attributes => { :style => "margin-bottom: 5px;"}

    product.remove
  end

end
