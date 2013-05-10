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
      message = ProductService.create_follower @product.prod_key, @user
      message.should_not be_nil
      message.should eql("success") 
      prod = Product.find_by_key( @product.prod_key )
      prod.users.count.should eq(1)
      prod.followers.should eq(1)
      subscribers = prod.users
      subscribers.size.should eq(1)
      sub_user = subscribers.first 
      sub_user.email.should eql(@user.email)
    end

    it "destroys a followers" do 
      message = ProductService.destroy_follower @product.prod_key, @user
      message.should_not be_nil
      message.should eql("success") 
      prod = Product.find_by_key( @product.prod_key )
      prod.followers.should eq(0)
      subscribers = prod.users
      subscribers.size.should eq(0)
      prod.users.count.should eq(0)
    end

    it "destroys returns error because product does not exist" do 
      message = ProductService.destroy_follower "_does_not_exist_", @user
      message.should_not be_nil
      message.should eql("error") 
    end

  end

end
