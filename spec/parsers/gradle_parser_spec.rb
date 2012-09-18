require 'spec_helper'

test_case_url = "https://s3.amazonaws.com/veye_test_env/dependencies.gradle"
describe GradleParser do
  
  describe "parse" do 
  	before :each do
  	  @product_1 = ProductFactory.create_for_maven("org.apache.httpcomponents", "httpclient", "4.1.2")
      @product_1.save

      @product_2 = ProductFactory.create_for_maven("com.sun", "tools", "1.6.0_26")
      @product_2.save

      @product_3 = ProductFactory.create_for_maven("junit-addons", "junit-addons", "1.4")
      @product_3.save

      @product_4 = ProductFactory.create_for_maven("net.sf.ehcache", "ehcache-core", "2.4.6")
      @product_4.save

      @product_5 = ProductFactory.create_for_maven("net.sf.ehcache", "ehcache-terracotta", "2.4.6")
      @product_5.save

      @product_6 = ProductFactory.create_for_maven("org.terracotta", "terracotta-toolkit-runtime", "3.3.0")
      @product_6.save

      @product_7 = ProductFactory.create_for_maven("org.springframework", "spring-test", "3.0.5.RELEASE")
      @product_7.save

      @product_8 = ProductFactory.create_for_maven("org.springframework.security",
      							"spring-security-core", "3.0.5.RELEASE")
      @product_8.save

      @product_9 = ProductFactory.create_for_maven("org.springframework.security", 
      	"spring-security-web", "3.0.5.RELEASE")

      @product_9.save

      @product_10 = ProductFactory.create_for_maven("gelfj", "gelfj", "0.9")
      @product_10.save

      @product_11 = ProductFactory.create_for_maven("javax.xml","jaxrpc","1.1")
      @product_11.save

      @product_12 = ProductFactory.create_for_maven("joda-time", "joda-time", "2.0")
      @product_12.save

      @product_13 = ProductFactory.create_for_maven("com.canoo.webtest", "webtest", "3.1-SNAPSHOT")
      @product_13.save
      
  	end

    after :each do
      @product_1.remove
      @product_2.remove
      @product_3.remove
      @product_4.remove
      @product_5.remove
      @product_6.remove
      @product_7.remove
      @product_8.remove
      @product_9.remove
      @product_10.remove
      @product_11.remove
      @product_12.remove
      @product_13.remove
    end
    it "parse from https the file correctly" do
      project = GemfileParser.parse(test_case_url)
      project.should_not be_nil
    end

    it "parse the file correctly" do
      
      #run tests
      project = GradleParser.parse(test_case_url)
      project.should_not be_nil

      dependency_01 = project.dependencies.first 
      dependency_01.name.should eql(@product_1.artifact_id)
      dependency_01.group_id.should eql(@product_1.group_id)
      dependency_01.artifact_id.should eql(@product_1.artifact_id)
      dependency_01.prod_key.should eql(@product_1.prod_key)
      dependency_01.version_requested.should eql("4.1.2")
      dependency_01.version_current.should eql(@product_1.version)
      dependency_01.comperator.should eql("=")
      dependency_01.scope.should eql("compile")

      dependency_02 = project.dependencies[1]
      dependency_02.name.should eql(@product_2.artifact_id)
      dependency_02.version_requested.should eql(@product_2.version)
      dependency_02.version_current.should eql(@product_2.version)
      dependency_02.comperator.should eql("=")
      dependency_02.scope.should eql("test")
      
    end
  
  end

end