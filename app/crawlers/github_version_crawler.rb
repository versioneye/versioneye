require 'octokit'

class GithubVersionCrawler

  include HTTParty

  A_USER_AGENT = "www.versioneye.com"
  A_API_URL    = "https://api.github.com"


  def initialize
    # create client and authenticate
    client = Octokit::Client.new \
      :client_id     => Settings.github_client_id,
      :client_secret => Settings.github_client_secret

    @github = client.root
  end

  def self.add_versions_to_all_products
    crawler = self.new
    products_with_empty_version_strings.each do |p|
      crawler.add_version_to_product( p.language, p.prod_key )
    end
  end

  def self.products_with_empty_version_strings
    Product.where({:language =>"Objective-C", "versions.version.ne" => nil }).all
  end


  def add_version_to_product (language, prod_key)

    # load product
    product = Product.find_by_lang_key(language, prod_key)

    # get git URL, owner and repo from product
    repo = product.repositories.map(&:repo_source).uniq.first
    github_versions = versions_for_github_url( repo )

    # update releases infos at version
    product.versions.each do |v|
      if v.released_string.to_s.empty?
        version_string = v.version.to_s
        v_hash = github_versions[version_string]
        v.released_at     = v_hash[:released_at]
        v.released_string = v_hash[:released_string]
      end
    end

    product.save
  end


  def versions_for_github_url github_url
    versions = {}

    parsed = GithubVersionCrawler.parse_github_url github_url
    tags   = tags_for_repo github_url

    tags.each do |t|

      owner  = parsed[:owner]
      repo   = parsed[:repo]
      v_name = t.name
      sha    = t.commit.sha

      meta = GithubVersionCrawler.commit_metadata owner, repo, sha

      begin
        date_string = meta["commit"]["author"]["date"].to_s
        date_time   = DateTime.parse date_string

        url = "#{A_API_URL}/repos/#{owner}/#{repo}/#{sha}"
        versions[v_name] = {
          :sha             => sha,
          :released_at     => date_time,
          :released_string => date_string,
        }
      rescue => e
        Rails.logger.error e
      end
    end

    versions
  end



  def self.commit_metadata owner, repo, sha
    url = self.commit_url owner, repo, sha

    response = HTTParty.get(url) #, :headers => {"User-Agent" => A_USER_AGENT } )

    Rails.logger.debug response

    if response.code == 200
      return JSON.parse(response.body)
    else
      Rails.logger.warn "Requested: #{url}\t response: #{response.code}"
      return nil
    end
  end

  def self.commit_url owner, repo, sha
    "#{A_API_URL}/repos/#{owner}/#{repo}/commits/#{sha}"
  end

  def tags_for_repo (github_url)
    uri_hash = GithubVersionCrawler.parse_github_url(github_url)
    return nil unless uri_hash

    repo = (@github.rels[:repository].get :uri => uri_hash).data
    tags = repo.rels[:tags].get.data
  end

  def self.parse_github_url (git_url)
    match = /https:\/\/github.com\/(.+)\/(.+)\.git/.match git_url
    parsed = {:owner => $1, :repo => $2}
    return false unless match
    parsed
  end

  def metadata_for_commit
    # curl https://api.github.com/repos/rmetzler/render-as-markdown/commits/725155400b35488ab65e8dd44264e055a397fd74
  end

end
