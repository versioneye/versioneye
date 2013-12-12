require 'spec_helper'

describe License do

  describe "link" do

    it "should return mit link" do
      license = License.new({:name => "MIT"})
      license.link.should eq("http://choosealicense.com/licenses/mit/")
    end
    it "should return mit link" do
      license = License.new({:name => "mit"})
      license.link.should eq("http://choosealicense.com/licenses/mit/")
    end
    it "should return mit link" do
      license = License.new({:name => "The MIT License"})
      license.link.should eq("http://choosealicense.com/licenses/mit/")
    end
    it "should return mit link" do
      license = License.new({:name => "MIT License"})
      license.link.should eq("http://choosealicense.com/licenses/mit/")
    end

    it "should return apache 2 link" do
      license = License.new({:name => "Apache License, Version 2.0"})
      license.link.should eq("http://www.apache.org/licenses/LICENSE-2.0.txt")
    end
    it "should return apache 2 link" do
      license = License.new({:name => "Apache License Version 2.0"})
      license.link.should eq("http://www.apache.org/licenses/LICENSE-2.0.txt")
    end
    it "should return apache 2 link" do
      license = License.new({:name => "The Apache Software License, Version 2.0"})
      license.link.should eq("http://www.apache.org/licenses/LICENSE-2.0.txt")
    end

  end

end

