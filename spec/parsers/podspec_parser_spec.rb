require 'spec_helper'

describe PodSpecParser do

  let!(:parser)  {PodSpecParser.new}

  describe '#parse_file' do
    it 'should create on product' do

    end


    describe 'parse same file again' do

      it 'should not create another product' do
      end

      it 'should not create another version' do
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
