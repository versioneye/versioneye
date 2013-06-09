require 'spec_helper'

describe PythonSetupParser do

  describe 'parse' do

    before(:each) do
      Product.destroy_all

      @testfile_url = 'https://s3.amazonaws.com/veye_test_env/setup.py'

      @parser = PythonSetupParser.new

      @product1 = ProductFactory.create_for_pip "dulwich",   "0.8.5"
      @product2 = ProductFactory.create_for_pip "argparse",  "1.0.0"
      @product3 = ProductFactory.create_for_pip "requests",  "1.2.9"
      @product4 = ProductFactory.create_for_pip "colorama",  "1.0.0"
      @product5 = ProductFactory.create_for_pip "jinja2",    "2.6"
      @product6 = ProductFactory.create_for_pip "Werkzeug",  "0.8.3"
      @product7 = ProductFactory.create_for_pip "markdown2", "2.0.1"
      @product8 = ProductFactory.create_for_pip "docutils",  "0.9.1"
      @product9 = ProductFactory.create_for_pip "textile",   "2.1.5"

      @product1.save
      @product2.save
      @product3.save
      @product4.save
      @product5.save
      @product6.save
      @product7.save
      @product8.save
      @product9.save
    end

    after :each do
      Product.destroy_all
    end

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
    end

    it "imports from S3 and parses successfully" do
      project = @parser.parse @testfile_url
      project.should_not be_nil
    end

    it "parses sample project correctly" do
      project = @parser.parse @testfile_url
      project.should_not be_nil

      project.dependencies.size.should eql(9)

      dep1 = fetch_by_name( project.dependencies, @product1.name)
      dep1.name.should eql(@product1.name)
      dep1.version_requested.should eql(@product1.version)
      dep1.comperator.should eql('==')

      dep2 = fetch_by_name( project.dependencies, @product2.name)
      dep2.name.should eql(@product2.name)
      dep2.version_requested.should eql(@product2.version)

      dep3 = fetch_by_name( project.dependencies, @product3.name)
      dep3.name.should eql(@product3.name)
      dep3.version_requested.should eql(@product3.version)
      dep3.version_label.should eql(">=1.1.0,<1.3.0")

      dep4 = fetch_by_name( project.dependencies, @product4.name)
      dep4.name.should eql(@product4.name)
      dep4.version_requested.should eql(@product4.version)
      dep4.comperator.should eql('==')

      dep5 = fetch_by_name( project.dependencies, @product5.name)
      dep5.name.should eql(@product5.name)
      dep5.version_requested.should eql(@product5.version)
      dep5.comperator.should eql('==')

      dep6 = fetch_by_name( project.dependencies, @product6.name)
      dep6.name.should eql(@product6.name)
      dep6.version_requested.should eql(@product6.version)
      dep6.comperator.should eql('==')

      dep7 = fetch_by_name( project.dependencies, @product7.name)
      dep7.name.should eql(@product7.name)
      dep7.version_requested.should eql(@product7.version)
      dep7.comperator.should eql('==')

      dep8 = fetch_by_name( project.dependencies, @product8.name)
      dep8.name.should eql(@product8.name)
      dep8.version_requested.should eql(@product8.version)
      dep8.comperator.should eql('==')

      dep9 = fetch_by_name( project.dependencies, @product9.name)
      dep9.name.should eql(@product9.name)
      dep9.version_requested.should eql(@product9.version)
      dep9.comperator.should eql('==')

    end
  end

end
