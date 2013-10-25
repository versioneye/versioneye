require 'spec_helper'

describe PodSpecParser do

  # describe '#parse' do

  # 	it "should read a podspec file and return product, date, version, dependencies, developer" do

  # 	end

  # end

  let (:parser)  {PodSpecParser.new}
  let (:podspec) {parser.load_spec './spec/fixtures/files/podspec/twitter-text-objc.podspec'}

  describe '#version' do
    let(:version) { parser.version podspec}
    
    it "should convert the version" do
      version.should be_a(Version)
      version.version.should eq "1.6.1" 
    end

    it "should convert the license" do
      version.license.should eq "Apache License, Version 2.0"
    end
  end

  describe '#repository' do
    let(:repo) { parser.repository podspec}

    it "should return a git repository" do
      repo.should be_a Repository
      repo.repo_type.should eq 'git'
      repo.repo_source.should eq 'https://github.com/twitter/twitter-text-objc.git'
    end

    it "should warn if there are other repositories" do
      # TODO
    end
  end

  describe '#developers' do
    let (:devs) {parser.developers podspec}
    it "should have developers" do
      devs.should be_a Array
      devs.size.should eq 1
      dev = devs[0]
      dev.should be_a Developer
      dev.language.should eq Product::A_LANGUAGE_OBJECTIVEC
      dev.prod_key.should eq "twitter-text-objc"
      dev.name.should eq "Twitter, Inc."
      dev.email.should eq "opensource@twitter.com"
    end
  end

end
