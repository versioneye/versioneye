require 'spec_helper'
require 'vcr'
require 'webmock'

describe BowerCrawler, :vcr do
  let(:token){ "8db49bc64f46ec9d73a4570903a24bf997b32a7e"}
  let(:url){ "https://github.com/versioneye/jquery" }
  let(:task){
    {
      repo_owner: "versioneye",
      repo_name: "jquery",
      repo_fullname: "versioneye/jquery",
      registry_name: "jquery"
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


  describe "crawl_projects" do


    it "creates correct product for jquery" do
      product_task = BowerCrawler.to_read_task(task, url)
      BowerCrawler.to_poison_pill(product_task[:task])
      VCR.use_cassette 'bower_crawler_jquery_specs_projects' do
        BowerCrawler.crawl_projects(token)
      end

      Product.all.count.should eq(1)
      prod = Product.all.first
      prod[:name].should eq("jquery")
      prod[:version].should eq('0.0.0+NA') # "2.1.1pre" in bower.json
      prod[:language].should eq(Product::A_LANGUAGE_JAVASCRIPT)
      prod[:prod_key].should eq("versioneye/jquery")

      prod.all_dependencies.count.should eq(0)
      prod.dependencies.count.should eq(0)

      #
      # Comment this out, because the dependencies are stored with the
      # version (2.1.1pre) from the bower.json file, but that version
      # is not released yet.
      #
      # prod.all_dependencies.count.should eq(4)
      # #it should have 1 required dependency
      # prod.dependencies.count.should eq(1)
      # dep = prod.dependencies.first
      # dep[:name].should eq("sizzle")
      # dep[:version].should eq("1.10.16")
      # dep[:prod_type].should eq(Project::A_TYPE_BOWER)
      # dep[:scope].should eq(Dependency::A_SCOPE_REQUIRE)

      #it should have 3 test dependencies
      # prod.dependencies(Dependency::A_SCOPE_DEVELOPMENT).count.should eq(3)
      # dev_deps = prod.dependencies(Dependency::A_SCOPE_DEVELOPMENT)

      # dev_deps[0][:name].should eq("requirejs")
      # dev_deps[0][:version].should eq("~2.1.8")
      # dev_deps[0][:prod_type].should eq(Project::A_TYPE_BOWER)
      # dev_deps[0][:scope].should eq(Dependency::A_SCOPE_DEVELOPMENT)

      # dev_deps[1][:name].should eq("qunit")
      # dev_deps[1][:version].should eq("~1.12.0")
      # dev_deps[1][:prod_type].should eq(Project::A_TYPE_BOWER)
      # dev_deps[1][:scope].should eq(Dependency::A_SCOPE_DEVELOPMENT)

      # dev_deps[2][:name].should eq("sinon")
      # dev_deps[2][:version].should eq("~1.7.3")
      # dev_deps[2][:prod_type].should eq(Project::A_TYPE_BOWER)
      # dev_deps[2][:scope].should eq(Dependency::A_SCOPE_DEVELOPMENT)

      # it creates correct links for product
      Versionlink.all.count.should eq(2)
      link1 = Versionlink.first
      link1[:name].should eq("SCM")
      link1[:prod_key].should eq("versioneye/jquery")
      link2 = Versionlink.all[1]
      link2[:name].should eq("Homepage")
      link2[:prod_key].should eq("versioneye/jquery")
    end


    it "creates correct versions from repo tags" do
      product_task = BowerCrawler.to_read_task(task, url)
      BowerCrawler.to_poison_pill(product_task[:task])
      BowerCrawler.crawl_projects(token)

      Product.all.count.should eq(1)
      prod = Product.all.first
      prod[:prod_key].should_not be_nil
      versions_task = BowerCrawler.to_version_task(task, prod[:prod_key])
      BowerCrawler.to_poison_pill(versions_task[:task])
      VCR.use_cassette('bower_crawler_jquery_specs_versions') do
        BowerCrawler.crawl_versions(token)
      end

      prod.reload
      prod.version.to_s.should eq('2.1.0')
      prod.versions.count.should eq(109)
      versions = prod.versions

      versions[0][:version].should eq("2.1.0-rc1")
      versions[1][:version].should eq("2.1.0-beta3")
      versions[2][:version].should eq("2.1.0-beta2")
      versions[3][:version].should eq("2.1.0-beta1")
      versions[4][:version].should eq("2.1.0")
      versions[5][:version].should eq("2.0.3")

      # check version archives
      Versionarchive.all.count.should eq(109)
      link = Versionarchive.all.asc(:created_at)[0]
      link[:prod_key].should eq("versioneye/jquery")
      link[:version_id].should eq("2.1.0-rc1")
      link[:language].should eq(Product::A_LANGUAGE_JAVASCRIPT)
    end

  describe "crawl_tag_project" do
    it "creates correct dependencies for every project file on tags" do
      product_task = BowerCrawler.to_read_task(task, url)
      BowerCrawler.to_poison_pill(product_task[:task])
      VCR.use_cassette('bower_crawler_jquery_spec_projects') do
        BowerCrawler.crawl_projects(token)
      end

      Product.all.count.should eq(1)
      prod = Product.all.first
      prod[:prod_key].should_not be_nil

      #versions_task = BowerCrawler.to_version_task(task, prod[:prod_key])
      BowerCrawler.to_poison_pill(BowerCrawler::A_TASK_READ_VERSIONS)
      VCR.use_cassette('bower_crawler_jquery_spec_versions') do
        BowerCrawler.crawl_versions(token)
      end

      prod.reload
      prod.versions.count.should eq(109)
      BowerCrawler.to_poison_pill(BowerCrawler::A_TASK_TAG_PROJECT)
      VCR.use_cassette('bower_crawler_jquery_spec_tag_projects') do
        BowerCrawler.crawl_tag_project(token)
      end

      deps1 = Dependency.find_by_lang_key_and_version(prod.language, prod.prod_key, "2.1.0").to_a
      deps1.size.should eq(4)
      deps1[0][:name].should eq("sizzle")
      deps1[0][:scope].should eq("require")
      deps1[0][:version].should eq("1.10.16")
      deps1[1][:name].should eq("requirejs")
      deps1[1][:scope].should eq("development")
      deps1[1][:version].should eq("~2.1.8")
      deps1[2][:name].should eq("qunit")
      deps1[2][:scope].should eq("development")
      deps1[2][:version].should eq("~1.12.0")
      deps1[3][:name].should eq("sinon")
      deps1[3][:scope].should eq("development")
      deps1[3][:version].should eq("~1.7.3")


      deps2 = Dependency.find_by_lang_key_and_version(prod.language, prod.prod_key, "1.0.0").to_a
      deps2.should be_empty

    end
  end


  end
end

