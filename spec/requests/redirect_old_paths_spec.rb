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

    product_2               = Product.new
    product_2.name          = "hibernate-core"
    product_2.name_downcase = "hibernate-core"
    product_2.prod_key      = "org.hibernate/hibernate-core"
    product_2.prod_type     = "Maven2"
    product_2.language      = "Java"
    product_2.version       = "1.0"
    product_2.versions      = Array.new
    product_2.versions.push( Version.new({:version => "1.0" }) )
    product_2.save

    product_3               = Product.new
    product_3.name          = "ocramius/proxy-manager"
    product_3.name_downcase = "ocramius/proxy-manager"
    product_3.prod_key      = "ocramius/proxy-manager"
    product_3.prod_type     = "Packgist"
    product_3.language      = "PHP"
    product_3.version       = "1.0"
    product_3.versions      = Array.new
    product_3.versions.push( Version.new({:version => "1.0" }) )
    product_3.save



    get "/package/json~gobi/version/1~1"
    response.should redirect_to("/ruby/json.gobi/1.1")

    get "/package_visual/json~gobi/version/1~1"
    response.should redirect_to("/ruby/json.gobi/1~1/visual_dependencies")

    get "/package/json~gobi"
    response.should redirect_to("/ruby/json.gobi/1.0")

    get "/product/json~gobi/1~0"
    response.should redirect_to("/ruby/json.gobi/1.0")

    get "/package/json.gobi/1~0"
    response.should redirect_to("/ruby/json.gobi/1.0")

    get "https://www.versioneye.com/package/php--ocramius--proxy-manager/badge.png"
    response.should redirect_to("https://www.versioneye.com/php/ocramius:proxy-manager/badge.png")

    get "/package/org~hibernate--hibernate-core/1~0"
    response.should redirect_to("/java/org.hibernate:hibernate-core/1.0")
  end

end
