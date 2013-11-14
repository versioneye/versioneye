require 'spec_helper'

describe PodfileParser do

  describe '.parse_file' do

    before :each do
      @parser = PodfileParser.new
    end

    def parse_and_check podfile_path
      podfile podfile_path
      check_project_created
    end

    def podfile filepath
      @project = @parser.parse_file filepath
    end

    def check_project_created
      @project.should be_true
      @project.language.should eq Product::A_LANGUAGE_OBJECTIVEC
      @project.project_type.should eq Project::A_TYPE_COCOAPODS
    end


    it "should read a simple podfile and return project, dependencies" do
      parse_and_check './spec/fixtures/files/pod_file/example1/Podfile'
    end

    it "should parse a podfile with target definitions" do
      parse_and_check './spec/fixtures/files/pod_file/target_example1/Podfile'
    end

    it "should parse linked targets in podfile" do
      parse_and_check './spec/fixtures/files/pod_file/target_example2/Podfile'
    end

  end

end
