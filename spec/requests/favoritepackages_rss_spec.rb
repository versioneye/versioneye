require 'spec_helper'

describe "UsersController" do

  before(:each) do
    User.destroy_all
    Product.destroy_all
    Notification.destroy_all
  end

  after(:each) do
    User.destroy_all
    Product.destroy_all
    Notification.destroy_all
  end

  it "ensure that favoritepackages.rss gets loaded" do
    user1 = UserFactory.create_new(103, true)
    user1.save

    product = ProductFactory.create_new(103)
    follow  = ProductService.follow(product.prod_key, user1)
    follow.should be_true

    product = Product.find_by_key( product.prod_key )

    created = CrawlerUtils.create_notifications product, "1.0.0"
    created.should eq(1)

    fav_path = "/users/#{user1.username}/favoritepackages.rss"
    get fav_path, nil, "HTTPS" => "on"
    assert_response :success
    response.body.should match( product.name     )
    response.body.should match( product.language )
    response.body.should match( "1.0.0"          )
  end

end
