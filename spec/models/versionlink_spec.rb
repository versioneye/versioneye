require 'spec_helper'

describe Versionlink do

  describe "create_project_link" do

    it "creates returns an existing link" do
      url      = 'http://rails.com'
      prod_key = 'rails'
      Versionlink.count.should eq(0)
      link = Versionlink.new({:language => Product::A_LANGUAGE_RUBY, :prod_key => prod_key, :link => url, :name => prod_key})
      id   = link.id.to_s
      link.save.should be_true
      link_db = Versionlink.create_project_link Product::A_LANGUAGE_RUBY, prod_key, url, prod_key
      link_db.should_not be_nil
      link_db.id.to_s.should eq(id)
    end

    it "creates a new link" do
      url      = 'http://rails.com'
      prod_key = 'rails'
      Versionlink.count.should eq(0)
      link_db = Versionlink.create_project_link Product::A_LANGUAGE_RUBY, prod_key, url, prod_key
      link_db.should_not be_nil
      Versionlink.count.should eq(1)
    end

    it "creates a new link, because the existing link is a version specific link" do
      url      = 'http://rails.com'
      prod_key = 'rails'
      Versionlink.count.should eq(0)
      link = Versionlink.new({:language => Product::A_LANGUAGE_RUBY, :prod_key => prod_key, :version_id => '3.0.0', :link => url, :name => prod_key})
      link.save.should be_true
      id = link.id.to_s
      link_db = Versionlink.create_project_link Product::A_LANGUAGE_RUBY, prod_key, url, prod_key
      link_db.should_not be_nil
      link_db.id.to_s.should_not eq(id)
      Versionlink.count.should eq(2)
    end

  end

end
