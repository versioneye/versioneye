require 'spec_helper'

describe BowerParser do
  let(:parser){ BowerParser.new }
  let(:prod1){FactoryGirl.create(:product_with_versions, name: "search", version: "3.0")}
  let(:prod2){FactoryGirl.create(:product_with_versions, name: "jquery", version: "3.0")}
  let(:prod3){FactoryGirl.create(:product_with_versions, name: "bootstrap", version: "3.0")}
  let(:prod4){FactoryGirl.create(:product_with_versions, name: "emberjs", version: "3.0")}
  let(:prod5){FactoryGirl.create(:product_with_versions, name: "websocket", version: "3.0")}
  let(:prod6){FactoryGirl.create(:product_with_versions, name: "validator", version: "3.0")}
  let(:prod7){FactoryGirl.create(:product_with_versions, name: "scss", version: "3.0")}
  let(:filepath){"/veye/bower.json"}
  let(:host){"https://s3-eu-west-1.amazonaws.com"}


  context "testing correctness of parser rules" do
    it "matches all main versions correctly" do
      "1".match(parser.rules[:main_version]).should_not be_nil
      "v1".match(parser.rules[:main_version]).should_not be_nil
      "1.0".match(parser.rules[:main_version]).should_not be_nil
      "v1.0".match(parser.rules[:main_version]).should_not be_nil
      "1.0.0".match(parser.rules[:main_version]).should_not be_nil
      "0.10.1".match(parser.rules[:main_version]).should_not be_nil
      "99.9.9".match(parser.rules[:main_version]).should_not be_nil
      "0.0.1000".match(parser.rules[:main_version]).should_not be_nil
    end

    it "matches full versions correctly" do
      "0.0.1".match(parser.rules[:full_version]).should_not be_nil
      "1.0.99".match(parser.rules[:full_version]).should_not be_nil
      "10.10.10-alpha".match(parser.rules[:full_version]).should_not be_nil
      "10.10.10-alpha1".match(parser.rules[:full_version]).should_not be_nil
      "10.10.10alpha1".match(parser.rules[:full_version]).should_not be_nil
      "10.10.10-alpha.12".match(parser.rules[:full_version]).should_not be_nil
      "10.10.10-alpha1.1.1".match(parser.rules[:full_version]).should_not be_nil
      "v10.10.10-alpha1.1.1".match(parser.rules[:full_version]).should_not be_nil
      "=10.10.10-alpha1.1.1".match(parser.rules[:full_version]).should_not be_nil
      "=v10.10.10-alpha1.1.1".match(parser.rules[:full_version]).should_not be_nil
      "10.10.10+build".match(parser.rules[:full_version]).should_not be_nil
      "10.10.10+build1".match(parser.rules[:full_version]).should_not be_nil
      "10.10.10+build1.1".match(parser.rules[:full_version]).should_not be_nil
      "10.10.10+build.1".match(parser.rules[:full_version]).should_not be_nil
      "v10.10.10+build.10".match(parser.rules[:full_version]).should_not be_nil
      "=10.10.10+build10.10".match(parser.rules[:full_version]).should_not be_nil
      "=v10.10.10+build10.10.1".match(parser.rules[:full_version]).should_not be_nil
      "10.10.10-release+build".match(parser.rules[:full_version]).should_not be_nil
      "10.10.10-r1.2+build".match(parser.rules[:full_version]).should_not be_nil
      "10.10.10-r1.2+build1.4".match(parser.rules[:full_version]).should_not be_nil
      "=  10.10.10-r1.2+build1.4".match(parser.rules[:full_version]).should_not be_nil
    end

    it "matches xranges correctly" do
      "0.x".match(parser.rules[:xrange_version]).should_not be_nil
      "1.*".match(parser.rules[:xrange_version]).should_not be_nil
      "1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
      "1.1.x".match(parser.rules[:xrange_version]).should_not be_nil
      "1.x.x".match(parser.rules[:xrange_version]).should_not be_nil
      "1.X.X".match(parser.rules[:xrange_version]).should_not be_nil
      "1.*.*".match(parser.rules[:xrange_version]).should_not be_nil
      "1.1.x-alpha".match(parser.rules[:xrange_version]).should_not be_nil
      "*.*".match(parser.rules[:xrange_version]).should_not be_nil
      "v 1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
      "= 1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
      "> 1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
      "< 1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
      "<= 1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
      ">= 1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
      ">= v1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
    end

    it "matches tilde versions correctly" do
      "~> 1".match(parser.rules[:tilde_version]).should_not be_nil
      "~> 1.0".match(parser.rules[:tilde_version]).should_not be_nil
    end

    it "matches caret version correctly" do
      "^1".match(parser.rules[:caret_version]).should_not be_nil
      "^1.0".match(parser.rules[:caret_version]).should_not be_nil
      "^ 1.0".match(parser.rules[:caret_version]).should_not be_nil
    end

    it "matches hyphen ranges correctly" do
      "1.0 - 1.5".match(parser.rules[:hyphen_version]).should_not be_nil
      "1.2.3 - 2.3.4".match(parser.rules[:hyphen_version]).should_not be_nil
    end

    it "matches star versions correctly" do
      "> *".match(parser.rules[:star_version]).should_not be_nil
      "<= *".match(parser.rules[:star_version]).should_not be_nil
    end
  end

  context "parsing project file from url" do
    it "parses project file from given url correctly " do
      parser = BowerParser.new
      project = parser.parse("#{host}#{filepath}")

      p "#-------------", project
      project.should_not be_nil
      project.dependencies.size.should eql(7)

      dep1 = project.dependencies[0]
      dep1.name.should eql(prod1[:name])
      dep1.version_requested.should eql("1.5")
      dep1.version_current.should eql("3.0")
      dep1.comperator.should eql("=")

      #TODO: finish it - do i need to test correctness of range of match
    end
  end

end
