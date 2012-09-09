require 'spec_helper'

describe ProjectParser do

  before(:each) do
    @user = User.new
    @user.fullname = "Hans Tanz"
    @user.username = "hanstanz"
    @user.email = "hans@tanz.de"
    @user.password = "password"
    @user.salt = "salt"
    @user.fb_id = "asggffffffff"
    @user.terms = true
    @user.datenerhebung = true
    @user.save
  end
  
  after(:each) do 
    @user.remove
  end
  
  before(:each) do
    @properties = Hash.new
  end
  
  describe "get_variable_value_from_pom" do 
    
    it "returns val" do 
      ProjectParser.get_variable_value_from_pom(@properties, "1.0").should eql("1.0")
    end
    
    it "returns still val" do
      @properties["springVersion"] = "3.1" 
      ProjectParser.get_variable_value_from_pom(@properties, "1.0").should eql("1.0")
    end
    
    it "returns value from the properties" do
      @properties["springversion"] = "3.1" 
      ProjectParser.get_variable_value_from_pom(@properties, "${springVersion}").should eql("3.1")
    end
    
    it "returns 3.1 because of downcase!" do
      @properties["springversion"] = "3.1" 
      ProjectParser.get_variable_value_from_pom(@properties, "${springVERSION}").should eql("3.1")
    end
    
    it "returns val because properties is empty" do 
      ProjectParser.get_variable_value_from_pom(@properties, "${springVersion}").should eql("${springVersion}")
    end

  end
  
end