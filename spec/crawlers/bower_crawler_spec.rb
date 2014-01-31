require 'spec_helper'
require 'vcr'
require 'webmock'

describe BowerCrawler, :vcr do
  let(:token){ "8db49bc64f46ec9d73a4570903a24bf997b32a7e"}
  let(:url){ "https://github.com/versioneye/backbone" }
  let(:task){
    {
      repo_owner: "versioneye",
      repo_name: "backbone",
      repo_fullname: "versioneye/backbone",
      registry_name: "backbone"
    }
  }

  before :all do
    FakeWeb.allow_net_connect = true

    VCR.configure do |c|
      c.cassette_library_dir = Rails.root.join("spec", "fixtures", "vcr_cassettes")
      c.ignore_localhost = true
      c.hook_into :webmock
      c.default_cassette_options = { record: :new_episodes }

      c.configure_rspec_metadata!
    end
  end

  describe 'url_to_repo_info' do
    it 'returns the right infos' do
      repo_url = "git://github.com/ZauberNerd/scroller.git"
      repo_info = BowerCrawler.url_to_repo_info repo_url
      repo_info.should_not be_nil
      repo_info[:owner].should eq("ZauberNerd")
      repo_info[:repo].should eq("scroller")
      repo_info[:full_name].should eq("ZauberNerd/scroller")
      repo_info[:url].should eq(repo_url)
    end
    it 'returns the right infos even with www' do
      repo_url = "git://www.github.com/ZauberNerd/scroller.git"
      repo_info = BowerCrawler.url_to_repo_info repo_url
      repo_info.should_not be_nil
      repo_info[:owner].should eq("ZauberNerd")
      repo_info[:repo].should eq("scroller")
      repo_info[:full_name].should eq("ZauberNerd/scroller")
      repo_info[:url].should eq(repo_url)
    end
    it 'returns nil because not on GitHub' do
      repo_url  = "git://bitbucket.com/ZauberNerd/scroller.git"
      repo_info = BowerCrawler.url_to_repo_info repo_url
      repo_info.should be_nil
    end
  end

  describe "crawl_projects" do
    it "creates correct product for backbone" do
      product_task = BowerCrawler.to_read_task(task, url)
      BowerCrawler.to_poison_pill(product_task[:task])
      VCR.use_cassette('bower_crawler_spec_projects') do
        BowerCrawler.crawl_projects(token)
      end

      Product.all.count.should eq(1)
      prod = Product.all.first
      prod[:name].should eq("backbone")
      prod[:version].should eq("0.0.0+NA")
      prod[:language].should eq(Product::A_LANGUAGE_JAVASCRIPT)
      prod[:prod_key].should eq("versioneye/backbone")

      prod.all_dependencies.count.should eq(1)
      prod.dependencies.count.should eq(1)
      dep = prod.all_dependencies.first
      dep[:name].should eq("underscore")
      dep[:version].should eq(">=1.5.0")
      dep[:prod_type].should eq(Project::A_TYPE_BOWER)
      dep[:scope].should eq(Dependency::A_SCOPE_REQUIRE)
    end
  end

  describe "crawl_versions" do
    it "creates correct versions from tags" do
      product_task = BowerCrawler.to_read_task(task, url)
      BowerCrawler.to_poison_pill(product_task[:task])
      VCR.use_cassette('bower_crawler_spec_projects') do
        BowerCrawler.crawl_projects(token)
      end


      Product.all.count.should eq(1)
      prod = Product.all.first
      prod[:prod_key].should_not be_nil

      versions_task = BowerCrawler.to_version_task(task, prod[:prod_key])
      BowerCrawler.to_poison_pill(versions_task[:task])
      VCR.use_cassette('bower_crawler_spec_versions') do
        BowerCrawler.crawl_versions(token)
      end

      prod.reload

      prod.versions.count.should eq(19)
      versions = prod.versions
      versions[0][:version].should eq("1.1.0")
      versions[1][:version].should eq("1.0.0")
      versions[2][:version].should eq("0.9.10")
      versions[3][:version].should eq("0.9.9")
      versions[4][:version].should eq("0.9.2")
      versions[5][:version].should eq("0.9.1")
    end
  end
end
