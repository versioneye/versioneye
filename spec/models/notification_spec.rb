require 'spec_helper'

describe Notification do
  
  before(:each) do
    @product = Product.new
    @product.name = "name"
    @product.prod_key = "gasgagasgj8623_junit/junit"
    @product.rate = 50
    @product.save
    
    @user = User.new
    @user.fullname = "Hans Tanz"
    @user.username = "hanstanz"
    @user.email = "hans@tanz.de"
    @user.password = "password"
    @user.salt = "salt"
    @user.terms = true
    @user.datenerhebung = true
    @user.save
    
    @follower = Follower.new
    @follower.user_id = @user.id.to_s
    @follower.product_id = @product.id.to_s
    @follower.notification = false
    @follower.save

    @notification = Notification.new
    @notification.user_id = @user.id.to_s
    @notification.product_id = @product.id.to_s
    @notification.version_id = "1.0"
    @notification.read = false
    @notification.sent_email = false;
    @notification.save
  end
  
  after(:each) do
    @user.remove
    @product.remove
    @follower.remove
    @notification.remove
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