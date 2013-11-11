require 'octokit'

class GithubVersionCrawler

  include HTTParty

  A_USER_AGENT = "curl/7.30.0"#www.versioneye.com"
  A_API_URL    = "https://api.github.com"


	def initialize
		# create client and authenticate
    @github = Octokit.root
	end

	def add_version (language, prod_key)

		# load product

    product = Product.find_by_lang_key(language, prod_key)

    # TODO get Git URL, owner and repo from product


    github_versions = GithubVersionCrawler.versions_for_github_url( github )

		# store releases infos at version
		product.versions.concat github_versions
    product.save
	end



  def self.versions_for_github_url github_url
    versions = []

    parsed = GithubVersionCrawler.parse_github_url git_url
    tags   = GithubVersionCrawler.tags_for_repo github_url
    versions = tags.map do |t|

      owner  = parsed[:owner]
      repo   = parsed[:repo]
      v_name = t.name
      sha    = t.commit.sha

      meta = GithubVersionCrawler.commit_metadata owner, repo, sha

      date_string = meta["commit"]["date"]
      date_time = DateTime.parse date_string

      url = "#{A_API_URL}/repos/#{owner}/#{repo}/#{sha}"
      version = Version.new({
        :version         => v_name,
        :released_at     => date_time,
        :released_string => date_string,
      })
      versions << version
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