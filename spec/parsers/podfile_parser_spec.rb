require 'spec_helper'

describe PodfileParser do

  let( :parser ) { PodfileParser.new }

  describe '.parse' do
    it 'parses remote urls' do
      project = parser.parse 'https://raw.github.com/CocoaPods/Core/master/spec/fixtures/Podfile'
      project.should be_true
      project.language.should eq Product::A_LANGUAGE_OBJECTIVEC
      project.project_type.should eq Project::A_TYPE_COCOAPODS
    end
  end

  describe '.parse_file' do

    def create_pods
      ssl_tool_kit = ProductFactory.create_for_cocoapods("SSToolkit", "2.3.4")
      ssl_tool_kit.save

      afnetworking = ProductFactory.create_for_cocoapods("AFNetworking", "0.2.1")
      afnetworking.versions.push(Version.new({:version => "0.2.0"}))
      afnetworking.save

      lumberjack   = ProductFactory.create_for_cocoapods("CocoaLumberjack", "1.2.3")
      lumberjack.versions.push(Version.new({:version => "1.2.0"}))
      lumberjack.save

      jsonkit   = ProductFactory.create_for_cocoapods("JSONKit", "1.1.0")
      jsonkit.versions.push(Version.new({:version => "1.2.0"}))
      jsonkit.save

      objection   = ProductFactory.create_for_cocoapods("Objection", "1.0.0")
      objection.save
    end

    def get_dependency project, name
      project.dependencies.each do |dep|
        return dep if dep.name.eql?( name )
      end
      return nil
    end

    def parse_and_check podfile_path
      project = parser.parse_file podfile_path
      project.should be_true
      project.language.should eq Product::A_LANGUAGE_OBJECTIVEC
      project.project_type.should eq Project::A_TYPE_COCOAPODS
      project
    end

    it "should read a simple podfile and return project, dependencies" do
      create_pods
      project = parse_and_check './spec/fixtures/files/pod_file/example1/Podfile'
      project.dependencies.count.should eq 6

      dep_ssl_tool_kit = get_dependency(project, "SSToolkit")
      dep_ssl_tool_kit.version_current.should eq "2.3.4"
      dep_ssl_tool_kit.version_requested.should eq "2.3.4"
      dep_ssl_tool_kit.outdated.should be_false

      dep_afnetworking = get_dependency(project, "AFNetworking")
      dep_afnetworking.version_current.should eq "0.2.1"
      dep_afnetworking.version_requested.should eq "0.2.1"
      dep_afnetworking.outdated.should be_false

      dep_lumberjack = get_dependency(project, "CocoaLumberjack")
      dep_lumberjack.version_current.should eq "1.2.3"
      dep_lumberjack.version_requested.should eq "1.2.3"
      dep_lumberjack.outdated.should be_false

      dep_jsonkit = get_dependency(project, "JSONKit")
      dep_jsonkit.version_current.should eq "1.2.0"
      dep_jsonkit.version_requested.should eq "1.1.0"
      dep_jsonkit.outdated.should be_true

      dep_jsonkit = get_dependency(project, "Objection")
      dep_jsonkit.version_current.should eq "1.0.0"
      dep_jsonkit.version_requested.should eq "1.0.0"
      dep_jsonkit.version_label.should eq ">= 0"
      dep_jsonkit.comperator.should eq ">="
      dep_jsonkit.outdated.should be_false
    end

    it "should parse a podfile with target definitions" do
      project = parse_and_check './spec/fixtures/files/pod_file/target_example1/Podfile'
    end

    it "should parse linked targets in podfile" do
      parse_and_check './spec/fixtures/files/pod_file/target_example2/Podfile'
    end

  end

end
