class GithubVersionCrawler

  include HTTParty

  def self.logger
    ActiveSupport::BufferedLogger.new('log/github_version_crawler.log')
  end

  # Crawle Release dates for Objective-C packages
  def self.crawl(language = Product::A_LANGUAGE_OBJECTIVEC, empty_release_dates = true, desc = true )
    products(language, empty_release_dates, desc).each do |product|
      add_version_to_product( product )
    end
  end

  def self.products( language, empty_release_dates, desc = true )
    products = Mongoid::Criteria.new(Product)
    if empty_release_dates
      products = Product.where({ :language => language, 'versions.released_at' => nil })
    else
      products = Product.where({ :language => language }) if !empty_release_dates
    end

    products = products.desc(:name) if desc
    products = products.asc(:name)  if !desc

    products.no_timeout
  end


  def self.add_version_to_product ( product )
    repo = product.repositories.map(&:src).uniq.first
    return nil if repo.to_s.empty?

    github_versions = versions_for_github_url( repo )
    return nil if github_versions.nil? || github_versions.empty?

    update_release_dates product, github_versions
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end


  def self.update_release_dates( product, github_versions )
    # update releases infos at version
    product.versions.each do |version|
      v_hash = version_hash github_versions, version.to_s
      next if v_hash.nil? || v_hash.empty?

      version.released_at     = v_hash[:released_at]
      version.released_string = v_hash[:released_string]
      product.save
      logger.info "update #{product.name} v #{version} was released at #{version.released_at}"
    end
    remaining = OctokitApi.client.ratelimit.remaining
    logger.info "check version dates for #{product.prod_key} - Remaining API requests: #{remaining}"
  end

  def self.version_hash github_versions, version_string
    version_hash = github_versions[version_string]
    if version_hash.nil? || version_hash.empty?
      # couldn't find 0.0.1, try v0.0.1
      version_hash = github_versions["v#{version_string}"]
      if version_hash.nil? || version_hash.empty?
        return
      end
    end
    version_hash
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
    logger.error e.message
    logger.error e.backtrace.join("\n")
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
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end

  def self.fetch_commit_date( owner_repo, sha )
    return nil unless owner_repo
    api = OctokitApi.client
    commit = api.commit(owner_repo, sha)
    commit_json = JSON.parse commit.to_json
    return commit_json["commit"]["committer"]["date"].to_s
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end

  def self.tags_for_repo( owner_repo )
    return nil unless owner_repo
    repo      = repo_data owner_repo
    tags      = repo.rels[:tags]
    tags.get.data
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end

  def self.repo_data owner_repo
    api  = OctokitApi.client
    root = api.root
    root.rels[:repository].get(:uri => owner_repo).data
  end

  def self.parse_github_url (git_url)
    match = /#{Settings.instance.github_base_url}\/(.+)\/(.+)\.git/.match git_url
    owner_repo = {:owner => $1, :repo => $2}
    if match.nil? || match == false
      logger.error "Couldn't parse #{git_url}"
      return nil
    end
    owner_repo
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end

end
