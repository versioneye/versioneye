require 'spec_helper'

describe Product do

  let( :product ) { Product.new(:language => Product::A_LANGUAGE_RUBY, :prod_key => "funny_bunny", :version => "1.0.0") }


  describe "encode_prod_key" do

    it "returns 0 for nil" do
      described_class.encode_prod_key(nil).should eq("0")
    end
    it "returns 0 for empty string" do
      described_class.encode_prod_key("").should eq("0")
    end
    it "returns 0 for empty string after strip" do
      described_class.encode_prod_key("  ").should eq("0")
    end
    it "returns rails" do
      described_class.encode_prod_key('rails').should eq('rails')
    end
    it "returns zend:zend" do
      described_class.encode_prod_key('zend/zend').should eq('zend:zend')
    end

  end

  describe "decode_prod_key" do

    it "returns nil for nil" do
      described_class.decode_prod_key(nil).should be_nil
    end
    it "returns nil for empty string" do
      described_class.decode_prod_key("").should be_nil
    end
    it "returns nil for empty string after strip" do
      described_class.decode_prod_key("  ").should be_nil
    end
    it "returns rails" do
      described_class.decode_prod_key('rails').should eq('rails')
    end
    it "returns zend/zend" do
      described_class.decode_prod_key('zend:zend').should eq('zend/zend')
    end

  end


  describe "encode_language" do

    it "returns nil for nil" do
      described_class.encode_language(nil).should be_nil
    end
    it "returns nil for empty string" do
      described_class.encode_language("").should be_nil
    end
    it "returns 0 for empty string after strip" do
      described_class.encode_language("  ").should be_nil
    end
    it "returns php" do
      described_class.encode_language('php').should eq('php')
    end
    it "returns php" do
      described_class.encode_language('PHP').should eq('php')
    end
    it "returns nodejs" do
      described_class.encode_language('Node.JS').should eq('nodejs')
    end
    it "returns objective-c" do
      described_class.encode_language('Objective-C').should eq('objective-c')
    end

  end


  describe "decode_language" do

    it "returns nil for nil" do
      described_class.decode_language(nil).should be_nil
    end
    it "returns nil for empty string" do
      described_class.decode_language("").should be_nil
    end
    it "returns 0 for empty string after strip" do
      described_class.decode_language("  ").should be_nil
    end
    it "returns PHP" do
      described_class.decode_language('php').should eq(described_class::A_LANGUAGE_PHP)
    end
    it "returns Node.JS" do
      described_class.decode_language('nodejs').should eq(described_class::A_LANGUAGE_NODEJS)
    end
    it "returns Objective-C" do
      described_class.decode_language('objective-c').should eq(described_class::A_LANGUAGE_OBJECTIVEC)
    end
    it "returns JavaScript" do
      described_class.decode_language('javascript').should eq(described_class::A_LANGUAGE_JAVASCRIPT)
    end
    it "returns Ruby" do
      described_class.decode_language('ruby').should eq(described_class::A_LANGUAGE_RUBY)
    end
    it "returns Ruby" do
      described_class.decode_language('rUBy').should eq(described_class::A_LANGUAGE_RUBY)
    end

  end


  describe 'language_esc' do

    it 'returns ruby' do
      product = described_class.new({:language => Product::A_LANGUAGE_RUBY})
      product.language_esc.should eq('ruby')
    end
    it 'returns nodejs' do
      product = described_class.new({:language => Product::A_LANGUAGE_NODEJS})
      product.language_esc.should eq('nodejs')
    end
    it 'returns objective-c' do
      product = described_class.new({:language => Product::A_LANGUAGE_OBJECTIVEC})
      product.language_esc.should eq('objective-c')
    end
    it 'returns titi' do
      product = described_class.new({:language => Product::A_LANGUAGE_OBJECTIVEC})
      product.language_esc('TiTi').should eq('titi')
    end

  end


  describe "find_by_id" do

    it "return nil. Because input is nil" do
      described_class.find_by_id(nil).should be_nil
    end

    it "return nil. Because input is empty" do
      result = described_class.find_by_id("  ")
      result.should be_nil
    end

    it "return nil. Because there are no results." do
      result = described_class.find_by_id("gasflasjgfaskjgas848asjgfasgfasgf")
      result.should be_nil
    end

    it "returns the product for string id" do
      product = described_class.new({:prod_key => 'junit', :name => 'junit'})
      product.save.should be_true
      result = described_class.find_by_id( product.id.to_s )
      result.should_not be_nil
      result.name.should eq('junit')
    end

    it "returns the product for object id" do
      product = described_class.new({:prod_key => 'junit', :name => 'junit'})
      product.save.should be_true
      result = described_class.find_by_id( product.id )
      result.should_not be_nil
      result.name.should eq('junit')
    end

  end


  describe "fetch_product" do

    it "return nil. Because all inputs are nil" do
      described_class.fetch_product(nil, nil).should be_nil
    end
    it "return nil. Because all inputs are empty" do
      described_class.fetch_product('', '').should be_nil
    end
    it "return nil. Because prod_key is nil" do
      described_class.fetch_product('ruby', nil).should be_nil
    end
    it "return nil. Because language is nil" do
      described_class.fetch_product(nil, 'xiki').should be_nil
    end
    it "returns nil because the language is wrong" do
      product1 = ProductFactory.create_for_gemfile('bee', '1.4.0')
      product1.versions.push( Version.new({version: '1.4.0'}) )
      product1.save
      described_class.fetch_product( Product::A_LANGUAGE_JAVA, "bee" ).should be_nil
    end
    it "returns nil because the prod_key is wrong" do
      product1 = ProductFactory.create_for_gemfile('bee', '1.4.0')
      product1.versions.push( Version.new({version: '1.4.0'}) )
      product1.save
      described_class.fetch_product( Product::A_LANGUAGE_RUBY, "bee_bee" ).should be_nil
    end
    it "returns product for package language" do
      product1 = ProductFactory.create_for_gemfile('bee', '1.4.0')
      product1.versions.push( Version.new({version: '1.4.0'}) )
      product1.save
      result = described_class.fetch_product( 'package', "bee" )
      result.should_not be_nil
      result.language.should eq('Ruby')
      result.prod_key.should eq('bee')
    end
    it "returns the searched product" do
      product1 = ProductFactory.create_for_gemfile('bee', '1.4.0')
      product1.versions.push( Version.new({version: '1.4.0'}) )
      product1.save
      described_class.fetch_product( Product::A_LANGUAGE_RUBY, "Bee" ).should_not be_nil
      described_class.fetch_product( Product::A_LANGUAGE_RUBY.downcase, "bee" ).should_not be_nil
      result = described_class.fetch_product( Product::A_LANGUAGE_RUBY, "bee" )
      result.should_not be_nil
      result.prod_key.should eql("bee")
    end

  end


  describe "find_by_key" do

    it "return nil. Because input is nil" do
      result = described_class.find_by_key(nil)
      result.should be_nil
    end
    it "return nil. Because input is empty" do
      result = described_class.find_by_key("  ")
      result.should be_nil
    end
    it "return nil. Because there are no results." do
      result = described_class.find_by_key("gasflasjgfaskjgas848asjgfasgfasgf")
      result.should be_nil
    end
    it "return searched product" do
      product = described_class.new({:prod_key => 'junit', :name => 'junit'})
      product.save.should be_true
      result = described_class.find_by_key('junit')
      result.should_not be_nil
      result.prod_key.should eq('junit')
      result.name.should eq('junit')
    end

  end


  describe "find_by_lang_key" do

    it "return nil. Because all inputs are nil" do
      described_class.find_by_lang_key(nil, nil).should be_nil
    end
    it "return nil. Because all inputs are empty" do
      described_class.find_by_lang_key('', '').should be_nil
    end
    it "return nil. Because prod_key is nil" do
      described_class.find_by_lang_key('ruby', nil).should be_nil
    end
    it "return nil. Because language is nil" do
      described_class.find_by_lang_key(nil, 'xiki').should be_nil
    end
    it "returns the searched product" do
      product1 = ProductFactory.create_for_gemfile('bee', '1.4.0')
      product1.versions.push( Version.new({version: '1.4.0'}) )
      product1.save
      described_class.find_by_lang_key( Product::A_LANGUAGE_JAVA, "bee" ).should be_nil
      described_class.find_by_lang_key( Product::A_LANGUAGE_RUBY, "Bee" ).should be_nil
      described_class.find_by_lang_key( Product::A_LANGUAGE_RUBY.downcase, "bee" ).should be_nil
      result = described_class.find_by_lang_key( Product::A_LANGUAGE_RUBY, "bee" )
      result.should_not be_nil
      result.prod_key.should eql("bee")
    end

  end


  describe "find_by_lang_key_case_insensitiv" do

    it "return nil. Because all inputs are nil" do
      described_class.find_by_lang_key_case_insensitiv(nil, nil).should be_nil
    end
    it "return nil. Because all inputs are empty" do
      described_class.find_by_lang_key_case_insensitiv('', '').should be_nil
    end
    it "return nil. Because prod_key is nil" do
      described_class.find_by_lang_key_case_insensitiv('ruby', nil).should be_nil
    end
    it "return nil. Because language is nil" do
      described_class.find_by_lang_key_case_insensitiv(nil, 'xiki').should be_nil
    end
    it "returns the searched product" do
      product1 = ProductFactory.create_for_gemfile('bee', '1.4.0')
      product1.versions.push( Version.new({version: '1.4.0'}) )
      product1.save
      described_class.find_by_lang_key_case_insensitiv( Product::A_LANGUAGE_JAVA, "bee" ).should be_nil
      described_class.find_by_lang_key_case_insensitiv( Product::A_LANGUAGE_RUBY, "Bee" ).should_not be_nil
      described_class.find_by_lang_key_case_insensitiv( Product::A_LANGUAGE_RUBY.downcase, "bee" ).should_not be_nil
      result = described_class.find_by_lang_key_case_insensitiv( Product::A_LANGUAGE_RUBY, "bee" )
      result.should_not be_nil
      result.prod_key.should eql("bee")
    end

  end


  describe "find_by_group_and_artifact" do

    it "returns nil because of wrong parameters" do
      described_class.find_by_group_and_artifact("bullshit", "bingo").should be_nil
    end
    it "returns nil because of wrong parameters" do
      described_class.find_by_group_and_artifact('', '').should be_nil
    end
    it "returns nil because of wrong parameters" do
      described_class.find_by_group_and_artifact(nil, nil).should be_nil
    end
    it "returns the correct product" do
      group = "junit56"
      artifact = "junit23"
      product.versions = Array.new
      product.name = artifact
      product.prod_key = "#{group}/#{artifact}"
      product.group_id = group
      product.artifact_id = artifact
      product.save
      version = Version.new
      prod = described_class.find_by_group_and_artifact(group, artifact)
      prod.should_not be_nil
      prod.group_id.should eql(group)
      prod.artifact_id.should eql(artifact)
    end

  end


  describe "by_prod_keys" do

    it "returns nil because of wrong parameters" do
      described_class.by_prod_keys(nil, nil).should be_empty
    end
    it "returns nil because of wrong parameters" do
      described_class.by_prod_keys('', '').should be_empty
    end
    it "returns nil because of wrong parameters" do
      described_class.by_prod_keys("bullshit", "bingo").should be_empty
    end
    it "returns the correct product" do
      product1 = ProductFactory.create_for_gemfile('xiki', '1.4.0')
      product1.versions.push( Version.new({version: '1.4.0'}) )
      product1.save
      product2 = ProductFactory.create_for_gemfile('tire', '1.4.0')
      product2.versions.push( Version.new({version: '1.4.0'}) )
      product2.save
      results = described_class.by_prod_keys(Product::A_LANGUAGE_RUBY, ['xiki', 'tire'])
      results.should_not be_nil
      results.size.should eq(2)
      results.first.name.should eq('xiki')
      results.last.name.should eq('tire')
    end

  end


  describe "http_links" do

    it "returns an empty array" do
      product.http_links.size.should eq(0)
    end

    it "returns one link" do
      link = Versionlink.new({language: product.language, prod_key: product.prod_key})
      link.link = "http://link.de"
      link.name = "Name"
      link.save.should be_true
      db_link = Versionlink.find(link.id)
      db_link.should_not be_nil
      links = product.http_links
      links.size.should eq(1)
      link.remove
    end

    it "returns an empty array" do
      link = Versionlink.new
      link.language = product.language
      link.prod_key = product.prod_key
      link.link = "http://link.de"
      link.version_id = "nope"
      link.name = "Name"
      link.save
      product.http_links.size.should eq(0)
      link.remove
    end

    it "returns 1 link" do
      link = Versionlink.new({language: product.language, prod_key: product.prod_key})
      link.link = "http://link.de"
      link.version_id = "1.1"
      link.name = "Name"
      link.save
      product.version = "1.1"
      product.http_version_links.size.should eq(1)
      link.remove
    end

  end


  describe "handling product licenses" do
    it "returns licence of product, that is added by crawler" do
      product1 = ProductFactory.create_for_gemfile("bee", "1.4.0")
      product1.versions.push( Version.new({version: "1.4.0"}) )
      product1.save
      license = License.new({:language => product1.language, :prod_key => product1.prod_key,
        :version => product1.version, :name => "MIT"})
      license.save
      product1.license_info.should eql("MIT")
      license = License.new({:language => product1.language, :prod_key => product1.prod_key,
        :version => product1.version, :name => "GLP"})
      license.save
      product1.license_info.should eql("MIT, GLP")
    end
  end

  describe "unique_languages_for_product_ids" do

    it "returns unique languages for the product" do
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      product_3 = ProductFactory.create_new 3, Project::A_TYPE_COMPOSER
      languages = described_class.unique_languages_for_product_ids( [product_1.id, product_2.id, product_3.id] )
      languages.size.should eq(2)
      languages.include?("PHP").should be_true
      languages.include?("Java").should be_true
    end

  end


  describe "update_used_by_count" do

    it "returns 0 because there are no deps" do
      product_1 = ProductFactory.create_new 1
      product_1.save
      product_1.update_used_by_count
      product_1.used_by_count.should eq(0)
    end

    it "returns 1 because there is 1 dep" do
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      dependency = Dependency.new({ :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => product_2.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency.save
      product_1.save
      product_1.update_used_by_count
      product_1.used_by_count.should eq(1)
    end

    it "returns still 1 because there are 2 deps from 1 product" do
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      dependency = Dependency.new({ :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => product_2.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency.save
      dependency2 = Dependency.new({ :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => "dev-master",
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency2.save
      product_1.save
      product_1.update_used_by_count
      product_1.used_by_count.should eq(1)
    end

    it "returns 2 because there are 2 deps" do
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      product_3 = ProductFactory.create_new 3
      dependency = Dependency.new({ :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => product_2.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency.save
      dependency2 = Dependency.new({ :language => product_3.language,
        :prod_key => product_3.prod_key, :prod_version => product_3.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency2.save
      product_1.save
      product_1.update_used_by_count
      product_1.used_by_count.should eq(2)
    end

  end


<<<<<<< Updated upstream
=======
  describe "version_by_number" do

    it "returns nil when number is nil" do
      product.version_by_number(nil).should be_nil
    end

    it "returns nil when product has no versions" do
      product.version_by_number("1.0.0").should be_nil
    end

    it "returns nil when prodoct has no matching versions" do
      product.versions << version1
      product.versions << version2
      product.save
      product.version_by_number("1.0.0").should be_nil
    end

    it "returns correct version when there's matching version" do
      product.versions.delete_all
      product.versions << version1
      product.versions << version2
      product.save
      version = product.version_by_number("0.0.1")
      version.should_not be_nil
      version.version.should eq('0.0.1')
    end

    it "should find correct version when there's massive set of subdoc" do
      product.versions.delete_all
      40.times do |i|
        product.versions << FactoryGirl.build(:product_version, version: "0.#{i}.1")
      end
      product.save
      match = product.version_by_number("0.12.1")
      match.should_not be_nil
      match[:version].should eql("0.12.1")
    end

    it "should find correct version even there may be versions with invalid or missing value" do
      product.versions.delete_all
      product.versions << version1
      product.versions << FactoryGirl.build(:product_version, version: nil)
      product.versions << FactoryGirl.build(:product_version, version: "")
      product.versions << FactoryGirl.build(:product_version, version: 1)
      product.versions << FactoryGirl.build(:product_version, version: 1.0)
      product.versions << FactoryGirl.build(:product_version, version: 1.minutes.ago)
      product.versions << version2
      product.save
      match = product.version_by_number(version2[:version])
      match.should_not be_nil
      match[:version].should eql(version2[:version])
    end

  end


  describe 'versions_empty?' do

    it 'returns true if versions nil' do
      product = Product.new
      product.versions = nil
      product.versions_empty?().should be_true
    end
    it 'returns true if versions empty' do
      product = Product.new
      product.versions = Array.new
      product.versions_empty?().should be_true
    end
    it 'returns false if versions not empty' do
      product = Product.new
      product.versions = Array.new
      product.versions.push(Version.new({:version => '1.0.0'}))
      product.versions_empty?().should be_false
    end

  end


  describe 'add_version' do

    it 'adds new version' do
      product = Product.new
      product.add_version('1.0.0')
      product.versions.size.should eq(1)
      product.versions_empty?().should be_false
      product.version_by_number('1.0.0').should_not be_nil
    end

    it 'doesnt add new version because its existing already' do
      product = Product.new
      product.add_version('1.0.0')
      product.versions.size.should eq(1)
      product.add_version('1.0.0')
      product.versions.size.should eq(1)
      product.versions_empty?().should be_false
      product.version_by_number('1.0.0').should_not be_nil
    end

  end


  describe 'check_nil_version' do

    it 'returns nil' do
      product = Product.new
      product.check_nil_version
      product.version.should be_nil
    end
    it 'returns 1.0.0' do
      product = Product.new
      product.versions.push(Version.new({:version => '1.0.0'}))
      product.check_nil_version
      product.version.should eq('1.0.0')
    end
    it 'returns 2.0.0' do
      product = Product.new({:version => '2.0.0'})
      product.check_nil_version
      product.version.should eq('2.0.0')
    end

  end


>>>>>>> Stashed changes
end
