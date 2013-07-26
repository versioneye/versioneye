require 'spec_helper'

describe ComposerParser do

  describe "parse" do

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
    end

    it "parse from http the file correctly" do
      product_01 = ProductFactory.create_for_composer("symfony/symfony", "2.0.7")
      product_01.versions.push( Version.new({ :version => "2.0.7-dev" }) )
      product_01.save

      parser  = ComposerParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/composer_vs/composer.json")
      project.should_not be_nil
      project.dependencies.size.should eql(1)

      dep_01 = fetch_by_name(project.dependencies, "symfony/symfony")
      dep_01.name.should eql("symfony/symfony")
      dep_01.version_requested.should eql("2.0.7")
      dep_01.version_current.should eql("2.0.7")
      dep_01.stability.should eql("stable")
      dep_01.comperator.should eql("=")
    end

  end

end
