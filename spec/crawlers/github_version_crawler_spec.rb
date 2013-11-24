require 'spec_helper'
require 'vcr'
require 'webmock'


RSpec.configure do |c|
  # so we can use :vcr rather than :vcr => true;
  # in RSpec 3 this will no longer be necessary.
  c.treat_symbols_as_metadata_keys_with_true_values = true

  c.around(:each, :vcr) do |example|
    name = example.metadata[:full_description].split(/\s+/, 2).join("/").underscore.gsub(/[^\w\/]+/, "_")
    options = example.metadata.slice(:record, :match_requests_on).except(:example_group)
    VCR.use_cassette(name, options) { example.call }
  end
end


describe GithubVersionCrawler, :vcr do

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

  after :all do
    # remove Webmock
    WebMock.allow_net_connect!

    VCR.configure do |c|
      c.allow_http_connections_when_no_cassette = true
    end

    # # restore Fakeweb
    # FakeWeb.allow_net_connect = false
    # FakeWeb.clean_registry
  end

	describe ".owner_and_repo" do

    example "1" do
      repo = 'https://github.com/0xced/ABGetMe.git'
      parsed = GithubVersionCrawler.parse_github_url(repo)

      # parsed.should_not be_nil
      parsed[:owner].should == '0xced'
      parsed[:repo].should  == 'ABGetMe'
    end
  end

  describe "#tags_for_repo" do
    # use_vcr_cassette

    it "returns tags" do
      url = 'https://github.com/0xced/ABGetMe.git'
      owner_repo = GithubVersionCrawler.parse_github_url url
      tags = GithubVersionCrawler.tags_for_repo owner_repo
      tags.should_not be_nil
      tags.length.should == 1
      t = tags.first
      t.name = '1.0.0'
      t.commit.sha = '8d8d7ca9f3429c952b83d1ecf03178e8efb99cb2'
    end
  end

  describe ".commit_metadata" do
    # use_vcr_cassette

    it "should return metadata for a commit" do
      meta = GithubVersionCrawler.fetch_commit_metadata 'rmetzler', 'render-as-markdown', '725155400b35488ab65e8dd44264e055a397fd74'

      meta.should_not be_nil
      meta["commit"]["author"]["name"].should eq("Richard Metzler")
    end
  end

  describe ".versions_for_github_url" do
    # use_vcr_cassette

    it "returns correct versions for render-as-markdown" do
      repo_url = 'https://github.com/rmetzler/render-as-markdown.git'
      versions = GithubVersionCrawler.versions_for_github_url repo_url
      versions.should_not be_nil
      versions.length.should eq(4)
    end

  end

end
