require 'spec_helper'

describe "Redirect Old Paths" do

  it "redirect old paths" do
    product               = Product.new
    product.name          = "json_gobi"
    product.name_downcase = "json_gobi"
    product.prod_key      = "json.gobi"
    product.prod_type     = "RubyGem"
    product.language      = "Ruby"
    product.version       = "1.0"
    product.versions      = Array.new
    product.versions.push( Version.new({:version => "1.0" }) )
    product.save

    get "/package/json~gobi"
    response.should redirect_to("/package/json.gobi")

    get "/product/json~gobi/version/1~0"
    response.should redirect_to("/package/json~gobi/version/1~0")

    get "/package/json~gobi/version/1~0"
    response.should redirect_to("/package/json.gobi/version/1.0")

    get "/package/json.gobi/version/1~0"
    response.should redirect_to("/package/json.gobi/version/1.0")

    get "/package/json.gobi/version/1.0"
    assert_response :success
  end

end
