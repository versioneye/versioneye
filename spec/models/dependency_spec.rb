require 'spec_helper'

describe Dependency do

  describe "remove_dependencies" do

    it "removes the dependencies" do
      described_class.count.should eq(0)
      dependency = described_class.new({:language => Product::A_LANGUAGE_PHP, :prod_key => 'symfony/symfony',
        :prod_version => '1.0.0', :name => 'symfony', :dep_prod_key => 'symfony.de' })
      dependency.save

      dependency_1 = described_class.new({:language => Product::A_LANGUAGE_PHP, :prod_key => 'symfony/symfony',
        :prod_version => '1.1.0', :name => 'symfony', :dep_prod_key => 'symfony.de' })
      dependency_1.save

      dependency_2 = described_class.new({:language => Product::A_LANGUAGE_PHP, :prod_key => 'symfony/doctrine',
        :prod_version => '1.0.0', :name => 'doctron', :dep_prod_key => 'symfony.de' })
      dependency_2.save

      described_class.count.should eq(3)
      described_class.remove_dependencies Product::A_LANGUAGE_PHP, 'symfony/symfony', '1.0.0'
      described_class.count.should eq(2)
      described_class.find_by_lang_key_and_version(dependency_1.language, dependency_2.prod_key, '1.0.0').should_not be_nil
      described_class.find_by_lang_key_and_version(dependency_1.language, dependency_1.prod_key, '1.1.0').should_not be_nil
      described_class.find_by_lang_key_and_version(dependency_1.language, dependency_1.prod_key, '1.0.0').should be_empty
    end

  end

  describe "update_known" do

    it "updates known with false" do
      dependency = Dependency.new({:prod_type => Project::A_TYPE_RUBYGEMS,
        :language => Product::A_LANGUAGE_RUBY, :prod_key => "rails",
        :prod_version => "4.0.0"})
      dependency.dep_prod_key = "Haste_net_gesehen"
      dependency.version = "1.0.0"
      dependency.known.should be_nil
      dependency.update_known
      dependency.known.should be_false
    end

    it "updates known with true" do
      product = Product.new({:prod_type => Project::A_TYPE_RUBYGEMS,
        :language => Product::A_LANGUAGE_RUBY, :prod_key => "activerecord",
        :version => "4.0.0"})
      product.save

      dependency = Dependency.new({:prod_type => Project::A_TYPE_RUBYGEMS,
        :language => Product::A_LANGUAGE_RUBY, :prod_key => "rails",
        :prod_version => "4.0.0"})
      dependency.dep_prod_key = "activerecord"
      dependency.version = "4.0.0"
      dependency.known.should be_nil
      dependency.update_known
      dependency.known.should be_true
    end

  end

  context "find_by_context" do

    describe "find_by" do

      before(:each) do
        @dependency = Dependency.new({ :language => Product::A_LANGUAGE_RUBY, :name => "bodo/bodo", :version => "1.0.1", :dep_prod_key => "bada/bada", :prod_key => "bum/bum", :prod_version => "1.1.1"})
        @dependency.save
      end

      after(:each) do
        @dependency.remove
      end

      it "returns the right dep" do
        dep = Dependency.find_by( Product::A_LANGUAGE_RUBY, "bum/bum", "1.1.1", "bodo/bodo", "1.0.1", "bada/bada")
        dep.should_not be_nil
        dep.name.should eql("bodo/bodo")
      end

      it "returns nil" do
        dep = Dependency.find_by( Product::A_LANGUAGE_RUBY, "bum/bum", "1.1.0", "bodo/bodo", "1.0.1", "bada/bada")
        dep.should be_nil
      end

    end

  end

end
