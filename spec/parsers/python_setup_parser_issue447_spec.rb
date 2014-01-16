require 'spec_helper'

<<-COMMENT
This spec covers our user issue with his setup.py file
which uses more spaces and \" as string literal.

COMMENT


describe PythonSetupParser do
  context 'parse' do
  
    let(:testfile_url){"https://s3.amazonaws.com/veye_test_env/python_1/setup.py"}
    let(:parser){PythonSetupParser.new}
    let(:product1){ProductFactory.create_for_pip "requests", "1.2.3"}
  
    it "imports from S3 successfully" do
      project = parser.parse testfile_url
      project.should_not be_nil
    end

    it "parses project file correctly" do
      product1.save
      project = parser.parse testfile_url
      project.should_not be_nil

      project.dependencies.size.should eq(1)

      dep1 = project.dependencies.first
      dep1.name.should eq(product1.name)
      dep1.version_requested.should eq(product1.version)

    end
  end
end
