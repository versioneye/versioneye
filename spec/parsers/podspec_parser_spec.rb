require 'spec_fast_helper'

describe PodSpecParser do

  describe '#parse_file' do

  
    it 'should create a product' do
      product1 = PodSpecParser.new.parse_file './spec/fixtures/files/podspec/Reachability.podspec'
      product1.should_not be_nil
      product1.language.should eq "Objective-C"
      product1.prod_key.should eq "reachability"
      product1.name.should eq "Reachability"
      product1.versions.size.should eq 1

      version = product1.versions.first
      version.version.should eq "3.1.1"
      version.license.should eq "BSD"
      Versionlink.count.should == 1
      #version.version_links.size.should eq 1

      Developer.count.should == 1
      #product1.developers.size.should eq 1
      #product1.repositories.size.should eq 1
    end


    describe 'parse same file again' do

      product1b = PodSpecParser.new.parse_file './spec/fixtures/files/podspec/Reachability.podspec'

      it 'should not create another product' do
        Product.fetch_product(product1b.language, product1b.prod_key).should be_a Product
      end

      it 'should not create another version' do
        product = Product.fetch_product(product1b.language, product1b.prod_key)
        product.versions.size.should == 1
      end

      it 'should not create more developers' do
      end

      it 'should not create more versionlinks' do
      end

    end

    describe 'parse other version file' do
      it 'should not create another product' do
      end

      it 'should create another version' do
      end
    end

    describe 'parse other podspec' do
      it 'should create another product' do

      end
    end

  end

  
  # describe '#parse_file' do
  #   @product = @parser.parser.parse_file('./spec/fixtures/files/podspec/Reachability.podspec')

  #   describe 'is not nil' do
  #     @product.should_not be_nil
  #   end
  # end

  # example 'simple example (Reachability.podspec)' do

  #   let(:product) {parser.parse_file('./spec/fixtures/files/podspec/Reachability.podspec')}

  #   describe 'is not nil' do
  #     product.should_not be_nil
  #   end

  #   describe 'it has a version' do
  #     product.version.should eq "BSD"
  #   end

  #   describe 'it has a repository' do
  #     product.repositories.size.should eq '1'
  #     repo = product.repositories.first
  #     repo.repo_type.should.eq "git"
  #     repo.repo_source.should.eq "https://github.com/tonymillion/Reachability.git"
  #   end

  #   describe 'it should have no dependencies' do
  #     product.dependencies.size.should eq 0
  #   end

    # describe '#developers' do
    #   let (:devs) {parser.developers podspec}
    #   it "should have developers" do
    #     devs.should be_a Array
    #     devs.size.should eq 1
    #     dev = devs[0]
    #     dev.should be_a Developer
    #     dev.language.should eq Product::A_LANGUAGE_OBJECTIVEC
    #     dev.prod_key.should eq "Reachability"
    #     dev.name.should eq "Tony Million"
    #     dev.email.should eq "tonymillion@gmail.com"
    #   end
    # end

    # describe '#versionlink' do
    #   let (:links) {parser.versionlinks podspec}

    #   it "should have a linked homepage" do
    #     links.size.should eq 1
    #     link = links[0]
    #     link.should be_a Versionlink
    #     link.link.should eq "https://github.com/tonymillion/Reachability"
    #     link.name = 'Homepage'
    #   end
    # end
  # end


  # describe 'twitter podspec' do
  #   let (:podspec) {parser.load_spec './spec/fixtures/files/podspec/twitter-text-objc.podspec'}

  #   describe '#version' do
  #     let(:version) { parser.version podspec}

  #     it "should convert the version" do
  #       version.should be_a(Version)
  #       version.version.should eq "1.6.1"
  #     end

  #     it "should convert the license" do
  #       version.license.should eq "Apache License, Version 2.0"
  #     end
  #   end

  #   describe '#repository' do
  #     let(:repo) { parser.repository podspec}

  #     it "should return a git repository" do
  #       repo.should be_a Repository
  #       repo.repo_type.should eq 'git'
  #       repo.repo_source.should eq 'https://github.com/twitter/twitter-text-objc.git'
  #     end

  #     it "should warn if there are other repositories" do
  #       # TODO
  #     end
  #   end

  #   describe '#dependencies' do
  #     let (:dep) {parser.dependencies podspec}

  #     it "should have no dependencies" do
  #       dep.size.should eq 0
  #     end

  #   end

  #   describe '#developers' do
  #     let (:devs) {parser.developers podspec}
  #     it "should have developers" do
  #       devs.should be_a Array
  #       devs.size.should eq 1
  #       dev = devs[0]
  #       dev.should be_a Developer
  #       dev.language.should eq Product::A_LANGUAGE_OBJECTIVEC
  #       dev.prod_key.should eq "twitter-text-objc"
  #       dev.name.should eq "Twitter, Inc."
  #       dev.email.should eq "opensource@twitter.com"
  #     end
  #   end

  #   describe '#versionlink' do
  #     let (:links) {parser.versionlinks podspec}

  #     it "should have a linked homepage" do
  #       links.size.should eq 1
  #       link = links[0]
  #       link.should be_a Versionlink
  #       link.link.should eq "https://github.com/twitter/twitter-text-objc"
  #       link.name = 'Homepage'
  #     end
  #   end
  # end

end
