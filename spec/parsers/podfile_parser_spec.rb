require 'spec_helper'

describe PodfileParser do

  describe '#parse' do

    it "should read a simple podfile and return project, dependencies" do
      parser = PodfileParser.new
      # project = parser.parse_file './spec/fixtures/files/podfile/very-simple.podfile'
      project = parser.parse_file './spec/fixtures/files/podfile/more-complex.podfile'

      project.should be_true
      project.language.should eq Product::A_LANGUAGE_OBJECTIVEC
      project.project_type.should eq Project::A_TYPE_COCOAPODS
    end

  end

end
