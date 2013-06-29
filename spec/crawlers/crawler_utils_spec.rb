require 'spec_helper'

describe CrawlerUtils do

  it "create_newest" do
    Newest.count.should eq(0)
    product = ProductFactory.create_new
    CrawlerUtils.create_newest product, "1.0.0"
    Newest.count.should eq(1)
    CrawlerUtils.create_newest product, "1.0.0"
    Newest.count.should eq(1)
  end

  it "creates a notification" do
    Notification.count.should eq(0)
    product = ProductFactory.create_new
    user_1 = UserFactory.create_new 1
    user_2 = UserFactory.create_new 2
    product.users << user_1
    product.users << user_2
    created = CrawlerUtils.create_notifications product, "1.0.0"
    created.should eq(2)
    Notification.count.should eq(2)
  end

end
