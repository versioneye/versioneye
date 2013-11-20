require 'spec_helper'

# This is the spec for the PodspecParser which parses Cocoapods .podspec files
#
# ATTENTION!
#
# I had to remove DatabaseCleaner.clean() in spec/support/database_cleaner.rb
# so it doesn't clean the database before/after each example.
# It seems like DatabaseCleaner should only be run for each TestGroup
#

describe CocoapodsPodspecParser do

  describe '#parse_file' do

    context 'parsing a single podspec' do

      it 'should create a product' do
        # should run before :all
        DatabaseCleaner.clean

        product = CocoapodsPodspecParser.new.parse_file './spec/fixtures/files/podspec/Reachability.podspec'
        product.should_not be_nil
        product.language.should eq 'Objective-C'
        product.prod_key.should eq 'reachability'
        product.name.should eq 'Reachability'
        product.versions.size.should == 1

        version = product.versions.first
        version.version.should eq '3.1.1'

        Versionlink.count.should == 1
        Developer.count.should == 1
        License.count.should == 1

        license = License.first
        license.name.should == 'BSD'
      end
    end

    context 'parsing the same file again' do

      it 'should not create another db entry' do
        #should run before all
        DatabaseCleaner.clean

        @product1a = CocoapodsPodspecParser.new.parse_file './spec/fixtures/files/podspec/Reachability.podspec'
        @product1b = CocoapodsPodspecParser.new.parse_file './spec/fixtures/files/podspec/Reachability.podspec'
        @language  = @product1b.language
        @prod_key  = @product1b.prod_key

        should_not_create_another_product
        should_not_create_another_version
        should_not_create_more_developers
        should_not_create_more_versionlinks
        should_not_create_more_licenses
      end

      def should_not_create_another_product
        products = Product.where(language:@language, prod_key:@prod_key)
        products.count.should == 1
        products.first.should be_a Product
      end

      def should_not_create_another_version
        products = Product.where(language:@language, prod_key:@prod_key)
        product = products.first

        versions = product.versions
        versions.size.should == 1
        version = versions.first
        version.version.should == '3.1.1'
      end

      def should_not_create_more_developers
        devs = Developer.where(language:@language, prod_key:@prod_key, version:'3.1.1')
        devs.count.should == 1
      end

      def should_not_create_more_versionlinks
        links = Versionlink.where(language:@language, prod_key:@prod_key, version_id:'3.1.1')
        links.count.should == 1
      end

      def should_not_create_more_licenses
        # License.count.should == 1
        License.each {|l| puts "License #{l.language} - #{l.prod_key} - #{l.version} : #{l.name}"}
        licenses = License.where(language:@language, prod_key:@prod_key, version:'3.1.1')
        licenses.count.should == 1
      end

    end

    context 'parse other version of the podspec' do

      it 'should create another version not another product' do
        # should run before :all
        DatabaseCleaner.clean

        @product1a = CocoapodsPodspecParser.new.parse_file './spec/fixtures/files/podspec/Reachability.podspec'
        @product1b = CocoapodsPodspecParser.new.parse_file './spec/fixtures/files/podspec/Reachability-newer.podspec'
        @language  = 'Objective-C'
        @prod_key  = 'reachability'

        should_not_create_another_product
        should_create_another_version
      end

      def should_not_create_another_product
        products = Product.where(language:@language, prod_key:@prod_key)
        products.count.should == 1
        products.first.should be_a Product
      end

      def should_create_another_version
        products = Product.where(language:@language, prod_key:@prod_key)
        product  = products.first
        versions = product.versions
        versions.size.should == 2

        version_numbers = versions.map(&:version)
        version_numbers.should include '3.1.1'
        version_numbers.should include '3.1.2'
      end

      def should_create_another_license
        licenses = License.where(language:@language, prod_key:@prod_key)
        licenses.size.should == 2

        license_names = licenses.map(&:name)
        license_names.should include 'BSD'
        license_names.should include 'MIT'
      end
    end

    context 'parse other podspec' do

      it 'should create another product and developer' do
        DatabaseCleaner.clean
        @product1 = CocoapodsPodspecParser.new.parse_file './spec/fixtures/files/podspec/Reachability.podspec'
        @product2 = CocoapodsPodspecParser.new.parse_file './spec/fixtures/files/podspec/twitter-text-objc.podspec'

        should_create_another_product
        should_create_another_developer
        should_create_another_license
      end

      def should_create_another_product
        Product.count.should == 2
      end

      def should_create_another_developer
        Developer.count.should == 2
      end

      def should_create_another_license
        License.count.should == 2
      end

    end


    it "should add subspecs as dependencies" do
      DatabaseCleaner.clean

      @product = CocoapodsPodspecParser.new.parse_file './spec/fixtures/files/podspec/subspec_ex1/RestKit.podspec'

      dependencies = Dependency.where({
        :language     => Product::A_LANGUAGE_OBJECTIVEC,
        :prod_type    => Project::A_TYPE_COCOAPODS,
        :prod_key     => 'RestKit'.downcase,
        :prod_version => '0.22.0'
        })

      dependencies.count.should eq(5)
      dependencies.map(&:name).should =~  %w{
        AFNetworking
        ISO8601DateFormatterValueTransformer
        RKValueTransformers
        SOCKit
        TransitionKit
        }
      # project_dep "RKValueTransformers" "~> 1.0.1"
      # project_dep "ISO8601DateFormatterValueTransformer" "~> 0.5.0"
      # project_dep "SOCKit" ">= 0 external_source=nil>"
      # project_dep "AFNetworking" "~> 1.3.0"
      # project_dep "TransitionKit" "= 2.0.0"
    end

  end

end

