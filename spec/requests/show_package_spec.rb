require 'spec_helper'

describe "show_package_controller" do
  let(:product){FactoryGirl.build(:product,
                                  name: "json",
                                  name_downcase: "json",
                                  prod_key: "json/json",
                                  version: "1.0",
                                  prod_type: Project::A_TYPE_RUBYGEMS,
                                  language: Product::A_LANGUAGE_RUBY,
                                 )}
  
  let(:product2){FactoryGirl.build(:product,
                                    name: "json_g",
                                    name_downcase: "json_g",
                                    prod_key: "json/json_g",
                                    version: "1.0",
                                    prod_type: Project::A_TYPE_RUBYGEMS,
                                    language: Product::A_LANGUAGE_RUBY
                                  )}

  before :each do
    Product.delete_all
  end

  after :each do
    Product.delete_all
  end

  it "show detail page for a package" do
    product.versions << Version.new({version: "1.0"})
    product.save
  
    results = MongoProduct.find_by_name( "json" )
    results.should_not be_nil
    results.size.should eq(1)

    #TODO: raises `stack too deep`
    get "/ruby/json:json/1.0"
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"
    assert_tag :tag => "section", :attributes => { :class => "container"}
    assert_tag :tag => "ul", :attributes => { :class => "nav pull-right"}
  end

  it "show visual page for a package" do
    product2.version = "1.0"
    product.versions << Version.new({version: "1.0"})
    product2.save

    results = MongoProduct.find_by_name( "json_g" )
    results.should_not be_nil
    results.size.should eq(1)

    get "/ruby/json:json_g/1.0/visual_dependencies"
    assert_response :redirect #:success
    # assert_select "form[action=?]", "/search"
    # assert_select "input[name=?]", "q"
    #assert_tag :tag => "h1", :attributes => { :style => "margin-bottom: 5px;"}
  end

end
