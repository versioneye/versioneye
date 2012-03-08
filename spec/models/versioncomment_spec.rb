require 'spec_helper'

describe Versioncomment do
  
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
    
    @vc = Versioncomment.new
    @vc.user_id = @user.id
    @vc.product_key = @product.id
  end
  
  after(:each) do 
    @vc.remove
    @user.remove
    @product.remove
  end
  
  describe "save" do
    
    it "does not save. Because mandatory fields are empty" do
      @vc.save.should be_false
    end
    
    it "does save. Because mandatory fields are not empty" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.rate = 40
      @vc.version = "1.0"
      @vc.save.should be_true
    end
    
  end
  
  describe "find_by_id" do
    
    it "returns nil" do
      vc = Versioncomment.find_by_id(888888888888)
      vc.should be_nil
    end
    
    it "returns the versioncomment" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.rate = 40
      @vc.version = "1.0"
      @vc.save
      vc = Versioncomment.find_by_id(@vc.id)
      vc.should_not be_nil
    end
    
  end
  
  describe "find_by_user_id" do
    
    it "returns nil" do
      vc = Versioncomment.find_by_user_id(888888888888)
      vc.should be_empty
    end
    
    it "returns the versioncomment" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.rate = 40
      @vc.version = "1.0"
      @vc.save
      vc = Versioncomment.find_by_user_id(@user.id)
      vc.should_not be_empty
      vc.size.should eql(1)
      vc[0].id.should eql(@vc.id)
    end
    
  end
  
  describe "find_by_prod_key_and_version" do
    
    it "returns an empty array" do
      vc = Versioncomment.find_by_prod_key_and_version("asfgasg", "a")
      vc.should be_empty
    end
    
    it "returns the versioncomments" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.rate = 40
      @vc.version = "1.0"
      @vc.save
      vcs = Versioncomment.find_by_prod_key_and_version(@product.id, "1.0")
      vcs.should_not be_empty
      vcs.size.should eql(1)
      vcs[0].id.should eql(@vc.id)
    end
    
  end
  
  describe "get_sum_by_prod_key_and_version" do
    
    it "returns 0" do
      sum = Versioncomment.get_sum_by_prod_key_and_version("asfgasg", "a")
      sum.should eql(0)
    end
    
    it "returns 60" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.rate = 40
      @vc.version = "1.0"
      @vc.save
      comment = Versioncomment.new
      comment.comment = "afgasfga"
      comment.rate = 20
      comment.version = "1.0"
      comment.user_id = @user.id
      comment.product_key = @product.id
      comment.save
      sum = Versioncomment.get_sum_by_prod_key_and_version(@product.id, "1.0")
      sum.should eql(60)
    end
    
    it "returns 90" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.rate = 40
      @vc.version = "1.0"
      @vc.save
      comment = Versioncomment.new
      comment.comment = "afgasfga"
      comment.rate = 50
      comment.version = "1.0"
      comment.user_id = @user.id
      comment.product_key = @product.id
      comment.save
      sum = Versioncomment.get_sum_by_prod_key_and_version(@product.id, "1.0")
      sum.should eql(90)
    end
    
  end
  
  describe "get_count_by_prod_key_and_version" do
    
    it "returns 0" do
      count = Versioncomment.get_count_by_prod_key_and_version("asfgasg", "a")
      count.should eql(0)
    end
    
    it "returns 2" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.rate = 40
      @vc.version = "1.0"
      @vc.save
      comment = Versioncomment.new
      comment.comment = "afgasfga"
      comment.rate = 20
      comment.version = "1.0"
      comment.user_id = @user.id
      comment.product_key = @product.id
      comment.save
      count = Versioncomment.get_count_by_prod_key_and_version(@product.id, "1.0")
      count.should eql(2)
    end
    
  end
  
  describe "get_average_rate_by_prod_key_and_version" do
    
    it "returns 0" do
      avg = Versioncomment.get_average_rate_by_prod_key_and_version("asfgasg", "a")
      avg.should eql(0)
    end
    
    it "returns 30" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.rate = 40
      @vc.version = "1.0"
      @vc.save
      comment = Versioncomment.new
      comment.comment = "afgasfga"
      comment.rate = 20
      comment.version = "1.0"
      comment.user_id = @user.id
      comment.product_key = @product.id
      comment.save
      avg = Versioncomment.get_average_rate_by_prod_key_and_version(@product.id, "1.0")
      avg.should eql(30)
    end
    
    it "returns 50" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.rate = 50
      @vc.version = "1.0"
      @vc.save
      comment = Versioncomment.new
      comment.comment = "afgasfga"
      comment.rate = 50
      comment.version = "1.0"
      comment.user_id = @user.id
      comment.product_key = @product.id
      comment.save
      avg = Versioncomment.get_average_rate_by_prod_key_and_version(@product.id, "1.0")
      avg.should eql(50)
    end
    
    it "returns 26" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.rate = 10
      @vc.version = "1.0"
      @vc.save
      comment = Versioncomment.new
      comment.comment = "afgasfga"
      comment.rate = 30
      comment.version = "1.0"
      comment.user_id = @user.id
      comment.product_key = @product.id
      comment.save
      
      comment2 = Versioncomment.new
      comment2.comment = "afgasfga"
      comment2.rate = 40
      comment2.version = "1.0"
      comment2.user_id = @user.id
      comment2.product_key = @product.id
      comment2.save
      
      avg = Versioncomment.get_average_rate_by_prod_key_and_version(@product.id, "1.0")
      avg.should eql(26)
    end
    
  end
  
  describe "user" do
    
    it "returns the user" do
      user = @vc.user
      user.should_not be_nil
      user.id.should eql(@user.id)
    end
    
  end
  
end