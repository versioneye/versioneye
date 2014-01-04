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

  describe "name_substitute" do

    it "should return MIT name" do
      license = License.new({:name => "MIT"})
      license.name_substitute.should eq("MIT")
    end
    it "should return MIT name" do
      license = License.new({:name => "MIT License"})
      license.name_substitute.should eq("MIT")
    end
    it "should return MIT name" do
      license = License.new({:name => "The MIT License"})
      license.name_substitute.should eq("MIT")
    end

    it "should return Apache License version 2 name" do
      license = License.new({:name => "The Apache Software License\, Version 2\.0"})
      license.name_substitute.should eq("Apache License, Version 2.0")
    end
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Apache License, Version 2.0"})
      license.name_substitute.should eq("Apache License, Version 2.0")
    end
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Apache License Version 2.0"})
      license.name_substitute.should eq("Apache License, Version 2.0")
    end
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Apache-2.0"})
      license.name_substitute.should eq("Apache License, Version 2.0")
    end


  end

end

