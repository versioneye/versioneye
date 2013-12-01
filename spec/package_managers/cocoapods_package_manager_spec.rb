require 'spec_helper'

describe CocoapodsPackageManager do

  def version string
    Version.new({:version => string})
  end

  def versions arr
    raise "no array" unless arr.is_a? Array
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
      example "'~> 0.1.0' means latest 0.1.x" do
        versions = versions(['0.2.0', '0.1.4', '0.1.1', '0.1.0', '0.0.9'])
        v = CocoapodsPackageManager.choose_version '~>', '0.1.0', versions
        v.should eq('0.1.4')
      end
    end
  end

  describe ".parse_requested_version" do

    context "version constraint is empty" do
      it "should return dependency with latest product version if " do
        product = Product.new({version: "1.0.2", versions: versions(['1.0.1', '1.0.2', '1.0.0'])})
        dependency = Projectdependency.new

        CocoapodsPackageManager.parse_requested_version(nil, dependency, product)

        dependency.version_requested.should eq('1.0.2')
      end
    end

    context "no product given" do
      it "should return the version string" do
        dependency = Projectdependency.new

        CocoapodsPackageManager.parse_requested_version('~>0.9', dependency, nil)

        dependency.version_requested.should eq('~>0.9')
        dependency.version_label.should eq('~>0.9')
      end
    end

    context "everything is there" do
      example "'~> 1.0.0' means latest 1.0.x" do

        product = Product.new({version: "1.0.2", versions: versions(['2.0.0', '1.1.0', '1.0.1', '1.0.2', '1.0.0'])})
        dependency = Projectdependency.new

        CocoapodsPackageManager.parse_requested_version('~> 1.0.0', dependency, product)

        dependency.version_label.should eq('~> 1.0.0')
        dependency.version_requested.should eq('1.0.2')
        dependency.comperator.should eq('~>')

      end
    end

  end

  describe ".spec_subspec" do
    def parse string
      CocoapodsPackageManager.spec_subspec(string)
    end

    it "returns nil for nil" do
      expect(parse(nil)).to eq(nil)
    end

    it "returns nil for empty string" do
      expect(parse("")).to eq(nil)
    end

    it "returns the string if there is no subspec" do
      spec, subspec = CocoapodsPackageManager.spec_subspec( 'spec' )
      expect(spec).to eq('spec')
      expect(subspec).to be_nil
    end

    it "returns spec/subspec" do
      expect(parse('spec/subspec')).to eq(%w{spec subspec})
    end
  end

end
