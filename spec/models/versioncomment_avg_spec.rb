require 'spec_helper'

describe Versioncomment do
  
  describe "get_flatted_average" do
    
    it "returns 10" do
      Versioncomment.get_flatted_average(1).should eql(10)
    end
    
    it "returns 10" do
      Versioncomment.get_flatted_average(7).should eql(10)
    end
    
    it "returns 10" do
      Versioncomment.get_flatted_average(14).should eql(10)
    end
    
    it "returns 20" do
      Versioncomment.get_flatted_average(15).should eql(20)
    end
    
    it "returns 20" do
      Versioncomment.get_flatted_average(24).should eql(20)
    end
    
    it "returns 20" do
      Versioncomment.get_flatted_average(21).should eql(20)
    end
    
    it "returns 30" do
      Versioncomment.get_flatted_average(25).should eql(30)
    end
    
    it "returns 30" do
      Versioncomment.get_flatted_average(32).should eql(30)
    end
    
    it "returns 30" do
      Versioncomment.get_flatted_average(34).should eql(30)
    end
    
    it "returns 40" do
      Versioncomment.get_flatted_average(35).should eql(40)
    end
    
    it "returns 40" do
      Versioncomment.get_flatted_average(44).should eql(40)
    end
    
    it "returns 50" do
      Versioncomment.get_flatted_average(45).should eql(50)
    end
    
    it "returns 50" do
      Versioncomment.get_flatted_average(54).should eql(50)
    end
    
    it "returns 50" do
      Versioncomment.get_flatted_average(144).should eql(50)
    end
   
  end
  
end