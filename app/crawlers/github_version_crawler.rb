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
    repo = product.repositories.map(&:repo_source).uniq.first
    return nil if repo.to_s.empty?

    github_versions = versions_for_github_url( repo )
    return nil if github_versions.nil? || github_versions.empty?

    update_release_dates product, github_versions
  rescue => e
    Rails.logger.error e.message
    e.backtrace.each.map{|trace| Rails.logger.error trace }
  end


  def self.update_release_dates( product, github_versions )
    # update releases infos at version
    product.versions.each do |version|
      if version.released_string.to_s.empty?
        version_string   = version.to_s
        v_hash           = github_versions[version_string]
        if v_hash.nil? || v_hash.empty?
          # couldn't find 0.0.1, try v0.0.1
          v_hash         = github_versions["v#{version_string}"]
          if v_hash.nil? || v_hash.empty?
            Rails.logger.info "No tag available for #{repo} - #{product.name} : #{version_string} / v#{version_string}"
            next
          end
        end
        version.released_at     = v_hash[:released_at]
        version.released_string = v_hash[:released_string]
        Rails.logger.info "update #{product.name} v #{version} was released at #{version.released_at}"
      end
    end

    product.save

    remaining = OctokitApi.instance.ratelimit.remaining
    Rails.logger.info "check version dates for #{product.prod_key} - Remaining API requests: #{remaining}"
  end


  def self.versions_for_github_url github_url
    versions   = {}
    owner_repo = parse_github_url github_url
    return nil if owner_repo.nil? || owner_repo.empty?

    tags_data  = tags_for_repo owner_repo
    return nil if tags_data.nil? || tags_data.empty?

    tags_data.tap do |t_data|
      t_data.each do |tag|
        process_tag( versions, tag, owner_repo )
      end
    end
    versions
  rescue => e
    Rails.logger.error e.message
    e.backtrace.each.map{|trace| Rails.logger.error trace }
    nil
  end


  def self.process_tag(versions, tag, owner_repo )
    v_name      = tag.name
    sha         = tag.commit.sha
    date_string = fetch_commit_date( owner_repo, sha )
    return nil if date_string.to_s.empty?
    date_time   = DateTime.parse date_string
    versions[v_name] = {
      :sha             => sha,
      :released_at     => date_time,
      :released_string => date_string,
    }
  rescue => e
    Rails.logger.error e.message
    e.backtrace.each.map{|trace| Rails.logger.error trace }
    nil
  end


  def self.fetch_commit_date( owner_repo, sha )
    return nil unless owner_repo
    repo        = repo_data owner_repo
    commit      = repo.rels[:commits].get(:sha => sha)
    commit_json = JSON.parse commit.data.to_json
    commit_json.first["commit"]["author"]["date"].to_s
  rescue => e
    Rails.logger.error e.message
    e.backtrace.each.map{|trace| Rails.logger.error trace }
    nil
  end


  def self.tags_for_repo( owner_repo )
    return nil unless owner_repo
    repo      = repo_data owner_repo
    tags      = repo.rels[:tags]
    tags_data = tags.get.data
    tags_data
  rescue => e
    Rails.logger.error e.message
    e.backtrace.each.map{|trace| Rails.logger.error trace }
    nil
  end


  def self.repo_data owner_repo
    api  = OctokitApi.instance
    root = api.root
    repo = root.rels[:repository].get(:uri => owner_repo).data
  end


  def self.parse_github_url (git_url)
    match = /https:\/\/github.com\/(.+)\/(.+)\.git/.match git_url
    owner_repo = {:owner => $1, :repo => $2}
    if match.nil? || match == false
      Rails.logger.error "Couldn't parse #{git_url}"
      return nil
    end
    owner_repo
  rescue => e
    Rails.logger.error e.message
    e.backtrace.each.map{|trace| Rails.logger.error trace }
    nil
  end

end
