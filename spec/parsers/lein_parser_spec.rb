require 'spec_helper'

describe LeinParser do

  describe "parse" do

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
    end

    it "read the file correctly" do
      parser = LeinParser.new
      project = parser.parse "https://s3.amazonaws.com/veye_test_env/project.clj"
      project.should_not be_nil
    end

    it "does it parse sample project correctly" do
      parser = LeinParser.new
    	project = parser.parse "https://s3.amazonaws.com/veye_test_env/project.clj"

      dependency_01 = fetch_by_name( project.dependencies, "clojure")
	    dependency_01.name.should eql("clojure")
	    dependency_01.group_id.should eql("org.clojure")
	    dependency_01.version_requested.should eql("1.3.0")
	    dependency_01.version_current.should eql(nil)
	    dependency_01.comperator.should eql("=")
	    dependency_01.scope.should eql(nil)

	    dependency_02 = fetch_by_name( project.dependencies, "jclouds")
	    dependency_02.name.should eql("jclouds")
	    dependency_02.group_id.should eql("org.jclouds")
	    dependency_02.version_requested.should eql("1.0")
	    dependency_02.version_current.should eql(nil)
	    dependency_02.comperator.should eql("=")
	    dependency_02.scope.should eql(Dependency::A_SCOPE_TEST)

	    dependency_03 = fetch_by_name( project.dependencies, "ehcache")
	    dependency_03.name.should eql("ehcache")
	    dependency_03.group_id.should eql("net.sf.ehcache")
	    dependency_03.version_requested.should eql("2.3.1")
	    dependency_03.version_current.should eql(nil)
	    dependency_03.comperator.should eql("=")
	    dependency_03.scope.should eql(nil)

	   	dependency_04 = fetch_by_name( project.dependencies, "log4j")
	    dependency_04.name.should eql("log4j")
	    dependency_04.group_id.should eql("log4j")
	    dependency_04.version_requested.should eql("1.2.15")
	    dependency_04.version_current.should eql(nil)
	    dependency_04.comperator.should eql("=")
	    dependency_04.scope.should eql(nil)

    end

  end

end
