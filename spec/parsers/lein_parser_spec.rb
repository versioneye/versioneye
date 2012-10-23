require 'spec_helper'

describe LeinParser do
  
  before(:each) do
    @properties = Hash.new
    @url = "https://s3.amazonaws.com/veye_test_env/sample.clj"
  end

  describe "parse" do 
    
    it "read the file correctly" do
      project = LeinParser.parse @url
      project.should_not be_nil
    end

    it "does it parse sample project correctly" do 
    	project = LeinParser.parse @url

   		dependency_01 = project[:dependencies].first 
	    dependency_01.name.should eql("clojure")
	    dependency_01.group_id.should eql("org.clojure")
	    dependency_01.version_requested.should eql("1.3.0")
	    dependency_01.version_current.should eql(nil)
	    dependency_01.comperator.should eql("=")
	    dependency_01.scope.should eql(nil)

	    dependency_02 = project[:dependencies][1]
	    dependency_02.name.should eql("jclouds")
	    dependency_02.group_id.should eql("org.jclouds")
	    dependency_02.version_requested.should eql("1.0")
	    dependency_02.version_current.should eql(nil)
	    dependency_02.comperator.should eql("=")
	    dependency_02.scope.should eql("test")

	    dependency_03 = project[:dependencies][2]
	    dependency_03.name.should eql("ehcache")
	    dependency_03.group_id.should eql("net.sf.ehcache")
	    dependency_03.version_requested.should eql("2.3.1")
	    dependency_03.version_current.should eql(nil)
	    dependency_03.comperator.should eql("=")
	    dependency_03.scope.should eql(nil)

	   	dependency_04 = project[:dependencies][3]
	    dependency_04.name.should eql("log4j")
	    dependency_04.group_id.should eql("log4j")
	    dependency_04.version_requested.should eql("1.2.15")
	    dependency_04.version_current.should eql(nil)
	    dependency_04.comperator.should eql("=")
	    dependency_04.scope.should eql(nil)

    end
  end

 end