require 'spec_helper'

describe GithubVersionCrawler do

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
    it "should return metadata for a commit" do
      meta = GithubVersionCrawler.fetch_commit_metadata 'rmetzler', 'render-as-markdown', '725155400b35488ab65e8dd44264e055a397fd74'

      meta.should_not be_nil
      meta["commit"]["author"]["name"].should eq("Richard Metzler")
    end
  end

  describe ".versions_for_github_url" do
    it "returns correct versions for render-as-markdown" do
      repo_url = 'https://github.com/rmetzler/render-as-markdown.git'
      versions = GithubVersionCrawler.versions_for_github_url repo_url
      versions.should_not be_nil
      versions.length.should eq(4)
    end

  end

end
