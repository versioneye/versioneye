require 'spec_helper'

<<-COMMENT
  This spec covers issue with user.x project file, which didnt have extras field
  and one item in requirements had 2 comparator:

  install_requires = ['argparse', 'requests>=1.1.0,<1.3.0', 'colorama']

  I, Timo, wrote some fixes that skip parsing when field is missing. And and patch
  to handle multiple comparators.
COMMENT

describe PythonSetupParser do
  describe 'parse' do
    before(:each) do
      @parser = PythonSetupParser.new
      @testfile_url = "https://raw.github.com/dotcloud/dotcloud-cli/master/setup.py"
      
      @product1 = ProductFactory.create_for_pip "argparse", "1.2.1"
      @product1.save

      @product2 = ProductFactory.create_for_pip "requests", "1.1.0"
      @product2.save

      @product3 = ProductFactory.create_for_pip "colorama", "0.2.5"
      @product3.save
    end

    after :each do
      Product.all.delete
    end

    it "imports from S3 successfully" do
      project = @parser.parse @testfile_url
      project.should_not be_nil
    end

    it "parses correctly that user submitted project" do
      project = @parser.parse @testfile_url
      project.should_not be_nil

      project.dependencies.count.should eql(3)

      dep1 = project.dependencies.shift
      dep1.name.should eql(@product1.name)

      dep2 = project.dependencies.shift
      dep2.name.should eql(@product2.name)
      dep2.version_requested.should eql(@product2.version)
      dep2.comperator.should eql('>=')

      dep3 = project.dependencies.shift
      dep3.name.should eql(@product3.name)

    end
  end
end
