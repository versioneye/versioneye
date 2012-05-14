require 'spec_helper'

describe Follower do
  
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
  end
  
  after(:each) do
    @user.remove
    @product.remove
    @follower.remove
  end
  
  describe "find_by_user_id_and_product" do
    
    it "returns nil. Id not valid." do
      follower = Follower.find_by_user_id_and_product(3444, "44444")
      follower.should be_nil
    end
    
    it "returns the only follower." do
      follower = Follower.find_by_user_id_and_product(@user.id, @product.id.to_s)
      follower.should_not be_nil
      follower.id.should eql(@follower.id)
    end
    
  end
  
  describe "find_by_product" do
    
    it "returns an empty array. Id not valid." do
      follower = Follower.find_by_product("44444")
      follower.should_not be_nil
      follower.count.should eql(0)
    end
    
    it "returns the only follower." do
      followers = Follower.find_by_product(@product.id.to_s)
      followers.should_not be_nil
      followers.count.should eql(1)
      followers[0].id.should eql(@follower.id)
    end
    
  end
  
  describe "find_notifications_by_user_id" do
    
    it "returns an empty array. Id not valid." do
      follower = Follower.find_notifications_by_user_id("44444")
      follower.should_not be_nil
      follower.count.should eql(0)
    end
    
    it "returns an empty array because follower don't have notifications." do
      followers = Follower.find_notifications_by_user_id(@user.id)
      followers.should_not be_nil
      followers.count.should eql(0)
    end
    
    it "returns the notifications." do
      @follower.notification = true
      @follower.save
      followers = Follower.find_notifications_by_user_id(@user.id)
      followers.should_not be_nil
      followers.count.should eql(1)
    end
    
  end

  describe "unfollow_all_by_user" do
    
    it "unfollows all" do
      followers = Follower.find_by_user( @user.id )
      followers.should_not be_nil
      followers.count.should eql(1)

      Follower.unfollow_all_by_user(@user.id)

      followers = Follower.find_by_user( @user.id )
      followers.should_not be_nil
      followers.count.should eql(0)
    end
    
  end
  
  describe "user" do
    
    it "returns the user" do
      user = @follower.user
      user.should_not be_nil
      user.id.should eql(@user.id)
    end
    
  end
  
end