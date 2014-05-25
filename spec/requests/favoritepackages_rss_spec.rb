require 'spec_helper'

describe "UsersController" do

  it "ensure that favoritepackages.rss gets loaded" do
    user1 = UserFactory.create_new(103, true)
    user1.save

    product = ProductFactory.create_new(103)
    follow  = ProductService.follow(product.language, product.prod_key, user1)
    follow.should be_true

    product = Product.fetch_product( product.language, product.prod_key )

    created = create_notifications product, "1.0.0"
    created.should eq(1)

    fav_path = "/users/#{user1.username}/favoritepackages.rss"
    get fav_path, nil, "HTTPS" => "on"
    assert_response :success
    response.body.should match( product.name     )
    response.body.should match( product.language )
    response.body.should match( "1.0.0"          )
  end

  def create_notifications(product, version_number, logger = nil)
    new_notifications = 0
    subscribers = product.users
    return new_notifications if subscribers.nil? || subscribers.empty?

    subscribers.each do |subscriber|
      success = create_notification( subscriber, product, version_number, logger )
      new_notifications += 1 if success
    end
    new_notifications
  rescue => e
    p e
    false
  end

  def create_notification user, product, version_number, logger
    notification            = Notification.new
    notification.user       = user
    notification.product    = product
    notification.version_id = version_number
    notification.save
  rescue => e
    p e
    false
  end

end
