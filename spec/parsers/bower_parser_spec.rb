require 'spec_helper'

describe BowerParser do
  let(:parser){ BowerParser.new }

  context "testing correctness of parser rules" do
    it "matches all main versions correctly" do
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
end
