require 'spec_helper'
require 'ruby-debug'

describe CocoapodsPackageManager do

  def version string
    Version.new({:version => string})
  end

  def versions *arr
    arr.map { |v_string| version(v_string) }
  end

  describe ".parse_requested_version" do
    it "parses '~> 1.2.3' into a hash" do
      hash = CocoapodsPackageManager.parse_version_constraint '~> 1.2.3'
      hash.should == {:comperator => '~>', :version_requested => '1.2.3'}
    end
  end

  describe ".choose_version" do
    describe "~>" do
      it "'~> 0.1.0' means latest 0.1.x" do
        # debugger
        versions = versions(['0.2.0', '0.1.4', '0.1.1', '0.1.0', '0.0.9'])
        v = CocoapodsPackageManager.choose_version '~>', '0.1.0', versions
        v.should eq('0.1.4')
      end
    end
  end

  describe ".parse_requested_version" do

    it "should return dependency with latest product version if version constraint is empty" do
      product = Product.new({version: "1.0.1", versions: versions('1.0.1', '1.0.2', '1.0.0')})
      dependency = Dependency.new

      CocoapodsPackageManager.parse_requested_version(nil, dependency, product)

      dependency.version.should eq('1.0.2')
    end

  end

end