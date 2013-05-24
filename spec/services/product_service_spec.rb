require 'spec_helper'

describe ProductService do

  describe "create_follower" do

    before(:all) do
      @product = ProductFactory.create_new(34)
      @user = UserFactory.create_new(34)
    end

    after(:all) do
      @product.remove
      @user.remove
    end

    it "creates a follower" do
      response = ProductService.follow @product.prod_key, @user
      response.should be_true
      prod = Product.find_by_key( @product.prod_key )
      prod.users.count.should eq(1)
      prod.followers.should eq(1)
      subscribers = prod.users
      subscribers.size.should eq(1)
      sub_user = subscribers.first
      sub_user.email.should eql(@user.email)
    end

    it "destroys a followers" do
      response = ProductService.unfollow @product.prod_key, @user
      response.should be_true
      prod = Product.find_by_key( @product.prod_key )
      prod.followers.should eq(0)
      subscribers = prod.users
      subscribers.size.should eq(0)
      prod.users.count.should eq(0)
    end

    it "destroys returns error because product does not exist" do
      unfollow = ProductService.unfollow "_does_not_exist_", @user
      unfollow.should be_false
    end

  end

end
