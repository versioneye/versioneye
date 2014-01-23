require 'spec_helper'

describe BowerParser do
  let(:parser){ BowerParser.new }
  let(:prod1){FactoryGirl.create(:product_with_versions, 
                                 prod_key: "search",
                                 name: "search", 
                                 prod_type: Project::A_TYPE_BOWER,
                                 language: Product::A_LANGUAGE_JAVASCRIPT
                                )}
  let(:prod2){FactoryGirl.create(:product_with_versions,
                                 prod_key: "jquery",
                                 name: "jquery", 
                                 prod_type: Project::A_TYPE_BOWER,
                                 language: Product::A_LANGUAGE_JAVASCRIPT 
                                )}
  let(:prod3){FactoryGirl.create(:product_with_versions,
                                 prod_key: "bootstrap",
                                 name: "bootstrap", 
                                 prod_type: Project::A_TYPE_BOWER,
                                 language: Product::A_LANGUAGE_JAVASCRIPT
                                )}
  let(:prod4){FactoryGirl.create(:product_with_versions,
                                 prod_key: "emberjs",
                                 name: "emberjs", 
                                 version: "3.0",
                                 prod_type: Project::A_TYPE_BOWER,
                                 language: Product::A_LANGUAGE_JAVASCRIPT
                                )}
  let(:prod5){FactoryGirl.create(:product_with_versions,
                                 prod_key: "websocket",
                                 name: "websocket", 
                                 version: "3.0",
                                 prod_type: Project::A_TYPE_BOWER,
                                 language: Product::A_LANGUAGE_JAVASCRIPT
                                )}
  let(:prod6){FactoryGirl.create(:product_with_versions,
                                 prod_key: "validator",
                                 name: "validator", 
                                 version: "3.0",
                                 prod_type: Project::A_TYPE_BOWER,
                                 language: Product::A_LANGUAGE_JAVASCRIPT
                                )}
  let(:prod7){FactoryGirl.create(:product_with_versions,
                                 prod_key: "scss",
                                 name: "scss", 
                                 version: "3.0",
                                 prod_type: Project::A_TYPE_BOWER,
                                 language: Product::A_LANGUAGE_JAVASCRIPT
                                )}
  let(:prod8){FactoryGirl.create(:product_with_versions,
                                 prod_key: "and-and",
                                 name: "and-and", 
                                 version: "2.0",
                                 prod_type: Project::A_TYPE_BOWER,
                                 language: Product::A_LANGUAGE_JAVASCRIPT
                                )}

  let(:prod9){FactoryGirl.create(:product_with_versions,
                                 prod_key: "or-or",
                                 name: "or-or", 
                                 version: "2.0",
                                 prod_type: Project::A_TYPE_BOWER,
                                 language: Product::A_LANGUAGE_JAVASCRIPT
                                )}


  let(:filepath){"/veye/bower.json"}
  let(:host){"https://s3-eu-west-1.amazonaws.com"}


  context "testing correctness of parser rules" do
    it "matches all main versions correctly" do
      "1".match(parser.rules[:main_version]).should_not be_nil
      m = "v1".match(parser.rules[:main_version])
      m.should_not be_nil
      m[:version].should eql("1")
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
      " =10.10.10-r1.2+build1.4".match(parser.rules[:full_version]).should_not be_nil
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
      "v1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
      "=1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
      ">1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
      "<1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
      "<=1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
      ">=1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
      ">=v1.1.*".match(parser.rules[:xrange_version]).should_not be_nil
    end

    it "matches tilde versions correctly" do
      "~>1".match(parser.rules[:tilde_version]).should_not be_nil
      "~>1.0".match(parser.rules[:tilde_version]).should_not be_nil
    end

    it "matches caret version correctly" do
      "^1".match(parser.rules[:caret_version]).should_not be_nil
      "^1.0".match(parser.rules[:caret_version]).should_not be_nil
      "^1.0".match(parser.rules[:caret_version]).should_not be_nil
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
    before :each do
      #FactoryGirl doesnt save them;
      prod1.versions << FactoryGirl.build(:product_version, version: "1.4")
      prod1.versions << FactoryGirl.build(:product_version, version: "1.5")
      prod1.versions << FactoryGirl.build(:product_version, version: "1.6")
      
      prod2.versions << FactoryGirl.build(:product_version, version: "1.8.0")
      prod2.versions << FactoryGirl.build(:product_version, version: "1.9.1")
      prod2.versions << FactoryGirl.build(:product_version, version: "1.9.3")

      prod3.versions << FactoryGirl.build(:product_version, version: "0.9")
      prod3.versions << FactoryGirl.build(:product_version, version: "1.3")
      prod3.versions << FactoryGirl.build(:product_version, version: "1.8")

      prod4.versions << FactoryGirl.build(:product_version, version: "2.1")
      prod4.versions << FactoryGirl.build(:product_version, version: "2.0")
      prod4.versions << FactoryGirl.build(:product_version, version: "1.4")
      prod4.versions << FactoryGirl.build(:product_version, version: "1.2")

      prod5.versions << FactoryGirl.build(:product_version, version: "0.0.1")
      prod5.versions << FactoryGirl.build(:product_version, version: "0.0.2")
      prod5.versions << FactoryGirl.build(:product_version, version: "0.1.0")
      
      prod6.versions << FactoryGirl.build(:product_version, version: "2.1")
      prod6.versions << FactoryGirl.build(:product_version, version: "2.0")
      prod6.versions << FactoryGirl.build(:product_version, version: "1.8")
      prod6.versions << FactoryGirl.build(:product_version, version: "1.4")
      
      prod7.versions << FactoryGirl.build(:product_version, version: "1.1")
      prod7.versions << FactoryGirl.build(:product_version, version: "1.3")
      prod7.versions << FactoryGirl.build(:product_version, version: "1.9")
      prod7.versions << FactoryGirl.build(:product_version, version: "2.0")
      
      prod8.versions << FactoryGirl.build(:product_version, version: "1.0")
      prod8.versions << FactoryGirl.build(:product_version, version: "1.1")
      prod8.versions << FactoryGirl.build(:product_version, version: "1.4")
      prod8.versions << FactoryGirl.build(:product_version, version: "1.6")
      prod8.versions << FactoryGirl.build(:product_version, version: "2.0")
      
      prod9.versions << FactoryGirl.build(:product_version, version: "1.0")
      prod9.versions << FactoryGirl.build(:product_version, version: "1.1")
      prod9.versions << FactoryGirl.build(:product_version, version: "1.2")
      prod9.versions << FactoryGirl.build(:product_version, version: "2.0")
 
      prod1.save;prod2.save;prod3.save;prod4.save;prod5.save;
      prod6.save;prod7.save;prod8.save;prod9.save
    
    end
    after :each do
      Product.delete_all
    end

    it "parses project file from given url correctly " do
      parser = BowerParser.new
      project = parser.parse("#{host}#{filepath}")

      project.should_not be_nil
      project.dependencies.size.should eql(9)

      dep1 = project.dependencies[0]
      dep1.name.should eql(prod1[:name])
      dep1.version_requested.should eql("1.5")
      dep1.version_current.should eql("1.6")
      dep1.comperator.should eql("=")
      dep1.outdated.should be_true

      dep2 = project.dependencies[1]
      dep2.name.should eql(prod2[:name])
      dep2.version_requested.should eql("1.9.3")
      dep2.version_current.should eql("1.9.3")
      dep2.comperator.should eql(">=")
      dep2.outdated.should be_false

      dep3 = project.dependencies[2]
      dep3.name.should eql(prod3[:name])
      dep3.version_requested.should eql("1.8")
      dep3.version_current.should eql("1.8")
      dep3.comperator.should eql("~")
      dep3.outdated.should be_false

      dep4 = project.dependencies[3]
      dep4.name.should eql(prod4[:name])
      dep4.version_requested.should eql("1.4")
      dep4.version_current.should eql("2.1")
      dep4.comperator.should eql("<")
      dep4.outdated.should be_true

      dep5 = project.dependencies[4]
      dep5.name.should eql(prod5[:name])
      dep5.version_requested.should eql("0.0.1")
      dep5.version_current.should eql("0.1.0")
      dep5.comperator.should eql("=")
      dep5.outdated.should be_true

      dep6 = project.dependencies[5]
      dep6.name.should eql(prod6[:name])
      dep6.version_requested.should eql("1.8")
      dep6.version_current.should eql("2.1")
      dep6.comperator.should eql("<=")
      dep6.outdated.should be_true

      dep7 = project.dependencies[6]
      dep7.name.should eql(prod7[:name])
      dep7.version_requested.should eql("1.9")
      dep7.version_current.should eql("2.0")
      dep7.comperator.should eql("<=")
      dep7.outdated.should be_true

      dep8 = project.dependencies[7]
      dep8.name.should eql(prod8[:name])
      dep8.version_requested.should eql("1.6")
      dep8.version_current.should eql("2.0")
      dep8.comperator.should eql("=")
      dep8.outdated.should be_true

      dep9 = project.dependencies[8]
      dep9.name.should eql(prod9[:name])
      dep9.version_requested.should eql("2.0")
      dep9.version_current.should eql("2.0")
      dep9.comperator.should eql("=")
      dep9.outdated.should be_false
 
    end
  end

end
