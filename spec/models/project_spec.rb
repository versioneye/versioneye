require 'spec_helper'

describe Project do
  
  before(:each) do
    @properties = Hash.new
  end
  
  describe "get_variable_value_from_pom" do 
    
    it "returns val" do 
      Project.get_variable_value_from_pom(@properties, "1.0").should eql("1.0")
    end
    
    it "returns still val" do
      @properties["springVersion"] = "3.1" 
      Project.get_variable_value_from_pom(@properties, "1.0").should eql("1.0")
    end
    
    it "returns value from the properties" do
      @properties["springversion"] = "3.1" 
      Project.get_variable_value_from_pom(@properties, "${springVersion}").should eql("3.1")
    end
    
    it "returns 3.1 because of downcase!" do
      @properties["springversion"] = "3.1" 
      Project.get_variable_value_from_pom(@properties, "${springVERSION}").should eql("3.1")
    end
    
    it "returns val because properties is empty" do 
      Project.get_variable_value_from_pom(@properties, "${springVersion}").should eql("${springVersion}")
    end

  end
  
  describe "is_version_current?" do 
    
    it "returns true" do 
      Project.is_version_current?("1.1.1", "1.1.9").should be_true
    end
    it "returns false" do 
      Project.is_version_current?("1.1.1", "1.2.0").should be_false
    end
    it "returns false" do 
      Project.is_version_current?("1.1.1", "1.2").should be_false
    end
    it "returns false" do 
      Project.is_version_current?("1.1.1", "2.0").should be_false
    end
    it "returns false" do 
      Project.is_version_current?("1.1.1", "2").should be_false
    end
    
  end
  
end