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

  # describe '#repository' do
  #   it "should return a git repository" do
  #   end

  #   it "should warn if there are other repositories" do
  #   end
  # end

  # describe '#developers' do
  #   it "should be empty without developers" do
  #     #PodSpecParser.developers(nil)
  #   end
  # end

end
