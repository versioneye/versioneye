require 'spec_helper'

describe "submit a versioncomment" do

  it "submit a versioncomment successfully" do
  	product = Product.new
  	product.versions = Array.new
    product.name = "json_gobi"
    product.name_downcase = "json_gobi"
    product.prod_key = "json_gobi"
    product.prod_type = "RubyGem"
    product.language = "Ruby"
    product.version = "1.0"
    version = Version.new
    version.version = "1.0"
    product.versions.push(version)
    product.save

    user = FactoryGirl.create(:default_user)

    post "/sessions", {:session => {:email => user.email, :password => user.password}}, "HTTPS" => "on"
    assert_response 302
    response.should redirect_to( new_user_project_path )

    get "/package/json_gobi"
    assert_response :success

    assert_tag :tag => "textarea", :attributes => { :class => "input span7", :id => "versioncomment_comment" }
    assert_tag :tag => "button",   :attributes => { :class => "btn2 btn-large"}

    post "/versioncomments", :versioncomment => {:comment => "This is a versioncomment XYZ123", :product_key => product.prod_key, :version => product.version}
    assert_response 302
    response.should redirect_to("/package/json_gobi/1.0")

    get "/package/json_gobi/1.0"
    response.body.should include "This is a versioncomment XYZ123"
  end

end
