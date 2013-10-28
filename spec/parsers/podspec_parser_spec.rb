require 'spec_helper'

# This is the spec for the PodSpecParser which parses Cocoapods .podspec files
#
# ATTENTION!
#
# I had to remove DatabaseCleaner.clean() in spec/support/database_cleaner.rb
# so it doesn't clean the database before/after each example.
# It seems like DatabaseCleaner should only be run for each TestGroup
#

describe PodSpecParser do

  describe '#parse_file' do

    context 'parsing a single podspec' do

      before :all do
        DatabaseCleaner.clean
      end

      it 'should create a product' do
        product = PodSpecParser.new.parse_file './spec/fixtures/files/podspec/Reachability.podspec'
        product.should_not be_nil
        product.language.should eq "Objective-C"
        product.prod_key.should eq "reachability"
        product.name.should eq "Reachability"
        product.versions.size.should == 1

        version = product.versions.first
        version.version.should eq "3.1.1"
        version.license.should eq "BSD"
        Versionlink.count.should == 1
        Developer.count.should == 1
      end
    end

    context 'parsing the same file again' do

      before :all do
        DatabaseCleaner.clean
        @product1a = PodSpecParser.new.parse_file './spec/fixtures/files/podspec/Reachability.podspec'
        @product1b = PodSpecParser.new.parse_file './spec/fixtures/files/podspec/Reachability.podspec'
        @language  = @product1b.language
        @prod_key  = @product1b.prod_key
      end

      it 'should not create another product' do
        products = Product.where(language:@language, prod_key:@prod_key)
        products.count.should == 1
        products.first.should be_a Product
      end

      it 'should not create another version' do
        products = Product.where(language:@language, prod_key:@prod_key)
        versions = products.first.versions
        versions.size.should == 1
        version = versions.first
        version.version.should == '3.1.1'
        version.license.should eq "BSD"
      end

      it 'should not create more developers' do
        devs = Developer.where(language:@language, prod_key:@prod_key, version:'3.1.1')
        devs.count.should == 1
      end

      it 'should not create more versionlinks' do
        links = Versionlink.where(language:@language, prod_key:@prod_key, version_id:'3.1.1')
        links.count.should == 1
      end

    end

    context 'parse other version of the podspec' do

      before :all do
        DatabaseCleaner.clean
        @product1a = PodSpecParser.new.parse_file './spec/fixtures/files/podspec/Reachability.podspec'
        @product1b = PodSpecParser.new.parse_file './spec/fixtures/files/podspec/Reachability-newer.podspec'
        @language  = 'Objective-C'
        @prod_key  = 'reachability'
      end

      it 'should not create another product' do
        products = Product.where(language:@language, prod_key:@prod_key)
        products.count.should == 1
        products.first.should be_a Product
      end

      it 'should create another version' do
        products = Product.where(language:@language, prod_key:@prod_key)
        versions = products.first.versions
        versions.size.should == 2

        version_numbers = versions.map(&:version)
        version_numbers.should include '3.1.1'
        version_numbers.should include '3.1.2'

        licenses = versions.map(&:license)
        licenses.should include 'BSD'
        licenses.should include 'MIT'

      end
    end

    context 'parse other podspec' do

      before :all do
        DatabaseCleaner.clean
        @product1 = PodSpecParser.new.parse_file './spec/fixtures/files/podspec/Reachability.podspec'
        @product2 = PodSpecParser.new.parse_file './spec/fixtures/files/podspec/twitter-text-objc.podspec'
      end

      it 'should exists another product' do
        Product.count.should == 2
      end

      it 'should exists another developer' do
        Developer.count.should == 2
      end

    end

  end

end

