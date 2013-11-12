class GithubVersionCrawler

  include HTTParty

  A_USER_AGENT = "www.versioneye.com"
  A_API_URL    = "https://api.github.com"

  # Crawle Release dates for Objective-C packages
  def self.crawl
    products_with_empty_version_strings.each do |product|
      add_version_to_product( product )
    end
  end

  def self.products_with_empty_version_strings
    Product.where({:language =>"Objective-C", "versions.version.ne" => nil }).all
  end

  def self.add_version_to_product ( product )
    # get git URL, owner and repo from product
    repo = product.repositories.map(&:repo_source).uniq.first
    github_versions = versions_for_github_url( repo )
    return nil if github_versions.nil?

    # update releases infos at version
    product.versions.each do |version|
      if version.released_string.to_s.empty?
        version_string          = version.version.to_s
        v_hash                  = github_versions[version_string]
        if v_hash.nil?
          p "Not tag available for #{product.name} : #{version_string}"
          next
        end
        version.released_at     = v_hash[:released_at]
        version.released_string = v_hash[:released_string]
        p "update version #{version.version} with #{version.released_at}"
      end
    end

    product.save
  end


  def self.versions_for_github_url github_url
    versions = {}
    owner_repo = parse_github_url github_url
    return nil  if owner_repo.nil?

    tags_data  = tags_for_repo owner_repo
    owner      = owner_repo[:owner]
    repo       = owner_repo[:repo]
    tags_data.tap do |t_data|
      t_data.each do |tag|
        process_tag(versions, tag, owner, repo)
      end
    end
    versions
  end


  def self.process_tag(versions, tag, owner, repo)
    v_name      = tag.name
    sha         = tag.commit.sha
    date_string = fetch_commit_date(owner, repo, sha)
    date_time   = DateTime.parse date_string
    url         = "#{A_API_URL}/repos/#{owner}/#{repo}/#{sha}"
    versions[v_name] = {
      :sha             => sha,
      :released_at     => date_time,
      :released_string => date_string,
    }
  rescue => e
    Rails.logger.error e.message
    p e.message
  end


  def self.fetch_commit_date(owner, repo, sha)
    meta = fetch_commit_metadata owner, repo, sha
    meta["commit"]["author"]["date"].to_s
  end


  def self.fetch_commit_metadata owner, repo, sha
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

  def self.tags_for_repo( owner_repo )
    return nil unless owner_repo
    api = OctokitApi.get_instance
    repo = api.rels[:repository].get(:uri => owner_repo).data
    tags = repo.rels[:tags]
    tags_data = tags.get.data
    tags_data
  end

  def self.parse_github_url (git_url)
    match = /https:\/\/github.com\/(.+)\/(.+)\.git/.match git_url
    owner_repo = {:owner => $1, :repo => $2}
    if match.nil? || match == false
      error = "Couldn't parse #{git_url}"
      p error
      Rails.logger.error error
      return nil
    end
    owner_repo
  end

end
