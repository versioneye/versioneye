require 'spec_helper'

describe Notification do
  
  before(:each) do
    @product = ProductFactory.create_new 
    @user = UserFactory.create_new 
    
    @notification = Notification.new
    @notification.user_id = @user.id.to_s
    @notification.product_id = @product.id.to_s
    @notification.version_id = "1.0"
    @notification.read = false
    @notification.sent_email = false;
    @notification.save
  end
  
  after(:each) do
    User.destroy_all
    Product.destroy_all
    Notification.destroy_all
  end
  
  describe "disable_all_for_user" do
    
    it "set all to true" do
      notifications = Notification.all( conditions: {sent_email: "false", user_id: @user.id.to_s} )
      notifications.should_not be_nil
      notifications.size.should eq(1)
      Notification.disable_all_for_user(@user.id)
      notifications = Notification.all( conditions: {sent_email: "false", user_id: @user.id.to_s} )
      notifications.should_not be_nil
      notifications.size.should eq(0)
    end
    
  end

end