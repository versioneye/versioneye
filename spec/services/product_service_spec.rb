require 'spec_helper'

describe ProductService do

  describe "create_follower" do

    let(:product){ ProductFactory.create_new(34) }
    let(:user)   { UserFactory.create_new(34) }

    it "creates a follower" do
      response = ProductService.follow product.language, product.prod_key, user
      response.should be_true
      prod = Product.fetch_product( product.language, product.prod_key )
      prod.users.count.should eq(1)
      prod.followers.should eq(1)
      subscribers = prod.users
      subscribers.size.should eq(1)
      sub_user = subscribers.first
      sub_user.email.should eql(user.email)
    end

    it "destroys a followers" do
      response = ProductService.follow   product.language, product.prod_key, user
      response.should be_true
      response = ProductService.unfollow product.language, product.prod_key, user
      response.should be_true
      prod = Product.fetch_product( product.language, product.prod_key )
      prod.followers.should eq(0)
      subscribers = prod.users
      subscribers.size.should eq(0)
      prod.users.count.should eq(0)
    end

    it "destroys returns error because product does not exist" do
      unfollow = ProductService.unfollow "lang", "_does_not_exist_", user
      unfollow.should be_false
    end

  end

  describe "update_version_data" do

    it "returns the one" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0" } ) )
      ProductService.update_version_data( product )
      product.version.should eql("1.0")
    end

    it "returns the highest stable" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0"     } ) )
      product.versions.push( Version.new( { :version => "1.1"     } ) )
      product.versions.push( Version.new( { :version => "1.2-dev" } ) )
      ProductService.update_version_data( product )
      product.version.should eql("1.1")
    end

    it "returns the highest unststable because there is no stable" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0-beta" } ) )
      product.versions.push( Version.new( { :version => "1.1-beta" } ) )
      product.versions.push( Version.new( { :version => "1.2-dev"  } ) )
      ProductService.update_version_data( product )
      product.version.should eql("1.2-dev")
    end

  end

end
