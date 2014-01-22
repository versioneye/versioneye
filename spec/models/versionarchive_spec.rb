require 'spec_helper'

describe Versionarchive do

  describe "create_archive_if_not_exist" do

    it "creates an archive" do
      described_class.count.should eq(0)
      archive = described_class.new({:language => Product::A_LANGUAGE_PHP, :prod_key => "symfony/symfony",
        :version_id => "1.0.0", :name => "symfony", :link => "symfony.de" })
      described_class.create_archive_if_not_exist archive
      described_class.count.should eq(1)
      arch_db = described_class.first
      arch_db.prod_key.should eql("symfony/symfony")
      arch_db.link.should eql("http://symfony.de")

      archive_2 = described_class.new({:language => Product::A_LANGUAGE_PHP, :prod_key => "symfony/symfony",
        :version_id => "1.0.0", :name => "symfony", :link => "symfony.de" })
      described_class.create_archive_if_not_exist archive_2
      described_class.count.should eq(1)

      archive_3 = described_class.new({:language => Product::A_LANGUAGE_PHP, :prod_key => "symfony/doctrine",
        :version_id => "1.0.0", :name => "doctron", :link => "symfony.de" })
      described_class.create_archive_if_not_exist archive_3
      described_class.count.should eq(2)

      archs = described_class.archives( archive.language, archive.prod_key, archive.version_id )
      archs.should_not be_nil
      archs.count.should eq(1)
      archs.first.prod_key.should eql(archive.prod_key)
    end

  end

  describe "create_if_not_exist_by_name" do

    it "creates an archive" do
      described_class.count.should eq(0)
      archive = described_class.new({:language => Product::A_LANGUAGE_PHP, :prod_key => "symfony/symfony",
        :version_id => "1.0.0", :name => "symfony", :link => "symfony.de" })
      described_class.create_if_not_exist_by_name archive
      described_class.count.should eq(1)
      arch_db = described_class.first
      arch_db.prod_key.should eql("symfony/symfony")
      arch_db.link.should eql("http://symfony.de")

      archive_2 = described_class.new({:language => Product::A_LANGUAGE_PHP, :prod_key => "symfony/symfony",
        :version_id => "1.0.0", :name => "symfony", :link => "symfony.de" })
      described_class.create_if_not_exist_by_name archive_2
      described_class.count.should eq(1)

      archive_3 = described_class.new({:language => Product::A_LANGUAGE_PHP, :prod_key => "symfony/doctrine",
        :version_id => "1.0.0", :name => "doctron", :link => "symfony.de" })
      described_class.create_if_not_exist_by_name archive_3
      described_class.count.should eq(2)

      archs = described_class.archives( archive.language, archive.prod_key, archive.version_id )
      archs.should_not be_nil
      archs.count.should eq(1)
      archs.first.prod_key.should eql(archive.prod_key)
    end

  end

  describe "remove_archives" do

    it "removes the archives" do
      described_class.count.should eq(0)
      archive = described_class.new({:language => Product::A_LANGUAGE_PHP, :prod_key => 'symfony/symfony',
        :version_id => '1.0.0', :name => 'symfony', :link => 'symfony.de' })
      archive.save

      archive_1 = described_class.new({:language => Product::A_LANGUAGE_PHP, :prod_key => 'symfony/symfony',
        :version_id => '1.1.0', :name => 'symfony', :link => 'symfony.de' })
      archive_1.save

      archive_2 = described_class.new({:language => Product::A_LANGUAGE_PHP, :prod_key => 'symfony/doctrine',
        :version_id => '1.0.0', :name => 'doctron', :link => 'symfony.de' })
      archive_2.save

      described_class.count.should eq(3)
      described_class.remove_archives Product::A_LANGUAGE_PHP, 'symfony/symfony', '1.0.0'
      described_class.count.should eq(2)
      described_class.archives(archive_1.language, archive_2.prod_key, '1.0.0').should_not be_nil
      described_class.archives(archive_1.language, archive_1.prod_key, '1.1.0').should_not be_nil
      described_class.archives(archive_1.language, archive_1.prod_key, '1.0.0').should be_empty
    end

  end

  describe "add_http" do

    it "adds http to the link" do
      link = "www.tutifruti.de/all.zip"
      link = described_class.add_http link
      link.should eql("http://www.tutifruti.de/all.zip")
    end

    it "does not ad http to the link" do
      link = "http://www.tutifruti.de/all.zip"
      link = described_class.add_http link
      link.should eql("http://www.tutifruti.de/all.zip")
    end

  end

end
