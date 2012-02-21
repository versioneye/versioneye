require 'spec_helper'

describe User do
  
  before(:each) do
    @user = User.new
  end
  
  describe "to_param" do
    it "returns username as default param" do
      @user.username = "hanstanz"
      @user.to_param.should eq('hanstanz')
    end
  end

  describe "create_verification" do
    it "generates a verification string" do
      @user.verification.should be_nil
      @user.create_verification
      @user.verification.should_not be_nil
    end
  end
  
  describe "activated?" do
    it "tests the activated? method" do 
      @user.create_verification
      @user.verification.should_not be_nil
      @user.activated?.should be_false
      @user.verification = nil
      @user.activated?.should be_true      
    end
  end
  
  describe "activate!" do
    it "tests the activated? method" do       
      email = "hans1@tanz.de"
      @user.fullname = "Hans1 Tanz"
      @user.username = "hanstanz1"
      @user.email = email
      @user.password = "password"
      @user.salt = "salt"
      @user.create_verification
      @user.save
      
      db_user = User.find_by_email( email )
      db_user.should_not be_nil
      db_user.verification.should_not be_nil
      db_user.activated?.should be_false
      User.activate!(@user.verification)
      
      db_user2 = User.find_by_email( email )
      db_user2.verification.should be_nil
      db_user2.activated?.should be_true
    end
  end
  
  describe "save" do
    it "saves a new user in the db" do 
      email = "hans@tanz.de"
      @user.fullname = "Hans Tanz"
      @user.username = "hanstanz"
      @user.email = email
      @user.password = "password"
      @user.salt = "salt"
      @user.save
      db_user = User.find_by_email( email )
      db_user.should_not be_nil
    end
  end
    
end