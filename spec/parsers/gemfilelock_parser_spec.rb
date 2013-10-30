require 'spec_helper'

describe GemfilelockParser do

  describe "parse" do

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
    end

    it "reads file correctly from web" do
      parser  = GemfilelockParser.new
      project = parser.parse "https://s3.amazonaws.com/veye_test_env/Gemfile.lock"
      project.should_not be_nil
    end

    it "parses test file correctly" do
      product1 = ProductFactory.create_for_gemfile("daemons", "1.1.4")
      product1.versions.push Version.new({version: "1.0.9"})
      product1.versions.push Version.new({version: "1.1.0"})
      product1.save

      product2 = ProductFactory.create_for_gemfile("eventmachine", "0.12.10")
      product2.versions.push Version.new({version: "0.12.6"})
      product2.save

      product3 = ProductFactory.create_for_gemfile("rack", "1.4.1")
      product3.versions.push Version.new({version: "1.4.1"})
      product3.versions.push Version.new({version: "1.3"})
      product3.versions.push Version.new({version: "1.3.6"})
      product3.versions.push Version.new({version: "1.3.9"})
      product3.save

      product4 = ProductFactory.create_for_gemfile "rack-protection", "1.2.0"
      product4.save

      product5 = ProductFactory.create_for_gemfile "sinatra", "1.3.3"
      product5.save

      product6 = ProductFactory.create_for_gemfile "tilt", "1.3.3"
      product6.save

      product7 = ProductFactory.create_for_gemfile "thin", "1.3.2"
      product7.save

      parser  = GemfilelockParser.new
      project = parser.parse "https://s3.amazonaws.com/veye_test_env/Gemfile.lock"

      project.should_not be_nil
      project.dependencies.size.should eql(7)
      project.dep_number.should eql(7)
      project.out_number.should eql(1)
      project.unknown_number.should eql(0)

      dep1 = fetch_by_name(project.dependencies, product1.name)
      dep1.name.should eql(product1.name)
      dep1.version_requested.should eql(product1.version)
      dep1.outdated.should be_false

      dep2 = fetch_by_name(project.dependencies, product2.name)
      dep2.name.should eql(product2.name)
      dep2.version_requested.should eql(product2.version)
      dep2.outdated.should be_false

      dep3 = fetch_by_name(project.dependencies, product3.name)
      dep3.name.should eql(product3.name)
      dep3.version_requested.should eql(product3.version)
      dep3.outdated.should be_false

      dep4 = fetch_by_name(project.dependencies, product4.name)
      dep4.name.should eql(product4.name)
      dep4.version_requested.should eql(product4.version)
      dep4.outdated.should be_false

      dep5 = fetch_by_name(project.dependencies, product5.name)
      dep5.name.should eql(product5.name)
      dep5.version_requested.should eql(product5.version)
      dep5.outdated.should be_false

      dep6 = fetch_by_name(project.dependencies, product6.name)
      dep6.name.should eql(product6.name)
      dep6.version_requested.should eql(product6.version)
      dep6.outdated.should be_false

      dep7 = fetch_by_name(project.dependencies, product7.name)
      dep7.name.should eql(product7.name)
      dep7.version_requested.should eql("1.3.1")
      dep7.outdated.should be_true
    end

  end

end
