require 'spec_helper'

test_case_url = "https://s3.amazonaws.com/veye_test_env/dependencies.gradle"

describe GradleParser do

  describe "parse" do

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
    end

    it "parse from https the file correctly" do
      parser  = GradleParser.new
      project = parser.parse(test_case_url)
      project.should_not be_nil
    end

    it "parse the file correctly" do
      product_1  = ProductFactory.create_for_maven("org.apache.httpcomponents", "httpclient", "4.1.2")
      product_2  = ProductFactory.create_for_maven("com.sun", "tools", "1.6.0_26")
      product_3  = ProductFactory.create_for_maven("junit-addons", "junit-addons", "1.4")
      product_4  = ProductFactory.create_for_maven("net.sf.ehcache", "ehcache-core", "2.4.6")
      product_5  = ProductFactory.create_for_maven("net.sf.ehcache", "ehcache-terracotta", "2.4.6")
      product_6  = ProductFactory.create_for_maven("org.terracotta", "terracotta-toolkit-runtime", "3.3.0")
      product_7  = ProductFactory.create_for_maven("org.springframework", "spring-test", "3.0.6.RELEASE")
      product_8  = ProductFactory.create_for_maven("org.springframework.security", "spring-security-core", "3.0.5.RELEASE")
      product_9  = ProductFactory.create_for_maven("org.springframework.security", "spring-security-web", "3.0.5.RELEASE")
      product_10 = ProductFactory.create_for_maven("gelfj", "gelfj", "0.9")
      product_11 = ProductFactory.create_for_maven("javax.xml","jaxrpc","1.1")
      product_12 = ProductFactory.create_for_maven("joda-time", "joda-time", "2.0")
      product_13 = ProductFactory.create_for_maven("com.canoo.webtest", "webtest", "3.1-SNAPSHOT")

      version_7         = Version.new
      version_7.version = "3.0.5.RELEASE"
      product_7.versions.push version_7

      product_1.save
      product_2.save
      product_3.save
      product_4.save
      product_5.save
      product_6.save
      product_7.save
      product_8.save
      product_9.save
      product_10.save
      product_11.save
      product_12.save
      product_13.save

      parser = GradleParser.new
      project = parser.parse(test_case_url)
      project.should_not be_nil

      dependency_01 = fetch_by_name( project.dependencies, product_1.artifact_id)
      dependency_01.name.should eql(product_1.artifact_id)
      dependency_01.group_id.should eql(product_1.group_id)
      dependency_01.artifact_id.should eql(product_1.artifact_id)
      dependency_01.prod_key.should eql(product_1.prod_key)
      dependency_01.version_requested.should eql("4.1.2")
      dependency_01.version_current.should eql(product_1.version)
      dependency_01.comperator.should eql("=")
      dependency_01.scope.should eql("compile")

      dependency_02 = fetch_by_name(project.dependencies, product_2.artifact_id)
      dependency_02.name.should eql(product_2.artifact_id)
      dependency_02.version_requested.should eql(product_2.version)
      dependency_02.version_current.should eql(product_2.version)
      dependency_02.comperator.should eql("=")
      dependency_02.scope.should eql(Dependency::A_SCOPE_TEST)

      dependency_03 = fetch_by_name(project.dependencies, product_3.name)
      dependency_03.name.should eql(product_3.artifact_id)
      dependency_03.version_requested.should eql(product_3.version)
      dependency_03.version_current.should eql(product_3.version)
      dependency_03.comperator.should eql("=")
      dependency_03.scope.should eql(Dependency::A_SCOPE_TEST)

      dependency_04 = fetch_by_name(project.dependencies, product_4.name)
      dependency_04.name.should eql(product_4.artifact_id)
      dependency_04.version_requested.should eql(product_4.version)
      dependency_04.version_current.should eql(product_4.version)
      dependency_04.comperator.should eql("=")
      dependency_04.scope.should eql("compile")

      dependency_05 = fetch_by_name(project.dependencies, product_5.name)
      dependency_05.name.should eql(product_5.artifact_id)
      dependency_05.version_requested.should eql(product_5.version)
      dependency_05.version_current.should eql(product_5.version)
      dependency_05.comperator.should eql("=")
      dependency_05.scope.should eql("compile")

      dependency_06 = fetch_by_name(project.dependencies, product_6.name)
      dependency_06.name.should eql(product_6.artifact_id)
      dependency_06.version_requested.should eql(product_6.version)
      dependency_06.version_current.should eql(product_6.version)
      dependency_06.comperator.should eql("=")
      dependency_06.scope.should eql("compile")

      dependency_07 = fetch_by_name(project.dependencies, product_7.name)
      dependency_07.name.should eql(product_7.artifact_id)
      dependency_07.version_requested.should eql("3.0.5.RELEASE")
      dependency_07.version_current.should eql("3.0.6.RELEASE")
      dependency_07.comperator.should eql("=")
      dependency_07.scope.should eql("runtime")

      dependency_08 = fetch_by_name(project.dependencies, product_8.name)
      dependency_08.name.should eql(product_8.artifact_id)
      dependency_08.version_requested.should eql(product_8.version)
      dependency_08.version_current.should eql(product_8.version)
      dependency_08.comperator.should eql("=")
      dependency_08.scope.should eql("compile")

      dependency_09 = fetch_by_name(project.dependencies, product_9.name)
      dependency_09.name.should eql(product_9.artifact_id)
      dependency_09.version_requested.should eql(product_9.version)
      dependency_09.version_current.should eql(product_9.version)
      dependency_09.comperator.should eql("=")
      dependency_09.scope.should eql("compile")

      dependency_10 = fetch_by_name(project.dependencies, product_10.name)
      dependency_10.name.should eql(product_10.artifact_id)
      dependency_10.version_requested.should eql(product_10.version)
      dependency_10.version_current.should eql(product_10.version)
      dependency_10.comperator.should eql("=")
      dependency_10.scope.should eql("compile")

      dependency_11 = fetch_by_name(project.dependencies, product_11.name)
      dependency_11.name.should eql(product_11.artifact_id)
      dependency_11.version_requested.should eql(product_11.version)
      dependency_11.version_current.should eql(product_11.version)
      dependency_11.comperator.should eql("=")
      dependency_11.scope.should eql("compile")

      dependency_12 = fetch_by_name(project.dependencies, product_12.name)
      dependency_12.name.should eql(product_12.artifact_id)
      dependency_12.version_requested.should eql(product_12.version)
      dependency_12.version_current.should eql(product_12.version)
      dependency_12.comperator.should eql("=")
      dependency_12.scope.should eql("compile")

      dependency_13 = fetch_by_name(project.dependencies, product_13.name)
      dependency_13.name.should eql(product_13.artifact_id)
      dependency_13.version_requested.should eql(product_13.version)
      dependency_13.version_current.should eql(product_13.version)
      dependency_13.comperator.should eql("=")
      dependency_13.scope.should eql(Dependency::A_SCOPE_TEST)

    end

  end

end
