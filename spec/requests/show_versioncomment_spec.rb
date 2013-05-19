require 'spec_helper'

describe "show_versioncomment" do

  it "show detail page for a versioncomment" do
  	product = Product.new
  	product.versions = Array.new
    product.name = "jsonbuo"
    product.name_downcase = "jsonbuo"
    product.prod_key = "jsonbuo"
    product.prod_type = "RubyGem"
    product.language = "Ruby"
    product.version = "1.0"
    version = Version.new
    version.version = "1.0"
    product.versions.push(version)
    product.save

    user = UserFactory.default
    user.save

    comment = Versioncomment.new
    comment.user_id = user.id
    comment.product_key = product.prod_key
    comment.prod_name = product.name
    comment.language = product.language
    comment.version = product.version
    comment.save

    get "/vc/#{comment.id}"
    assert_response :success

    user.remove
    comment.remove
    product.remove
  end

end
