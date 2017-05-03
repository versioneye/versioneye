require 'spec_helper'

describe "search" do
  let(:product){FactoryGirl.build(:product,
                                  name: "json",
                                  name_downcase: "json",
                                  prod_key: "json/json",
                                  version: "1.0",
                                  prod_type: Project::A_TYPE_RUBYGEMS,
                                  language: Product::A_LANGUAGE_RUBY)}
  let(:product2){FactoryGirl.build(:product,
                                    name: "jsonHP",
                                    name_downcase: "jsonhp",
                                    prod_key: "json/jsonhp",
                                    language: "Java",
                                    prod_type: 'Maven')}

  before :each do
    EsProduct.reset
  end

  after :each do
    Product.delete_all
  end

  it "shows the default search" do
    get "/search", params: {:q => ""}
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"
    assert_select "div#search-results"
  end

  it "show the search with 1 result" do
    version = Version.new({:version => "1.0"})
    product.versions << version
    product.save
    version.save

    results = MongoProduct.find_by_name( "json" )
    results.should_not be_nil
    results.size.should eq(1)

    EsProduct.index_all

    get "/search", params: {:q => "json"}
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"
    assert_select "div#search-results"
    assert_select "div[class=?]", "row search-item"
    assert_select "a[class=?]", "searchResultLink"
  end

  it "shows the search with 2 result" do
    product.versions << Version.new({version: "1.0"})
    product.save

    product2.versions << Version.new({version: "1.0"})
    product2.save

    results = MongoProduct.find_by_name( "json" )
    results.should_not be_nil
    results.size.should eq(2)

    EsProduct.index_newest

    get "/search", params: {:q => "json"}
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"
    assert_select "div#search-results"
    assert_select "input[id=?]", "q"
    assert_select "input[name=?]", "q"
    assert_select "input[value=?]", "json"
    assert_select "input[type=?]", "text"
    assert_select "div[class=?]", "row search-item"
    assert_select "a[class=?]", "searchResultLink"
  end
end
