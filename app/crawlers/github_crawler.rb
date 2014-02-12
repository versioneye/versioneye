class GithubCrawler

  include HTTParty

  def self.logger
    ActiveSupport::BufferedLogger.new('log/github.log')
  end

  def self.crawl
    crawl = self.crawle_object
    resources = self.get_first_level_list
    logger.info "#{resources.count} resources to crawle"
    resources.each do |resource|
      crawle_package resource.name, crawl, resource
    end
    crawl.duration = Time.now - crawl.created_at
    crawl.save
    self.logger.info(" *** This crawle took #{crawl.duration} *** ")
    return nil
  end

  def self.get_first_level_list
    ProductResource.where(:resource_type => 'GitHub')
  end

  def self.crawle_package name, crawl = nil, resource = nil
    logger.info "crawl package #{name}"
    repository = OctokitApi.client.repo name
    return nil if repository.nil?

    product = fetch_product repository, resource.force_fullname
    update_product product, repository
    create_or_update_github_link product, repository

    tags = repository.rels[:tags].get.data
    tags.each do |tag|
      next if tag.nil?

      version_number = CrawlerUtils.remove_version_prefix tag.name
      next if product.version_by_number( version_number )

      create_version repository, tag, product, version_number
      create_archive repository, tag, product, version_number
      update_resource resource, product
    end
  rescue => e
    self.logger.error "ERROR in crawle_package(#{name}) Message: #{e.message}"
    self.logger.error e.backtrace.join('\n')
    nil
  end

  def self.create_version repository, tag, product, version_number
    version = Version.new({version: version_number})
    set_release_date version, repository, tag
    product.versions << version
    product.save
    logger.info "New version #{product.language} : #{product.prod_key} : #{version_number}"

    CrawlerUtils.create_newest( product, version_number, logger )
    CrawlerUtils.create_notifications( product, version_number, logger )
  end

  def self.create_archive repository, tag, product, version_number
    link = "https://api.github.com/repos/#{repository.full_name}/tarball/#{tag.name}"
    name = "#{repository.full_name}_#{tag.name}.tar.gz"
    archive = Versionarchive.new({language: product.language, prod_key: product.prod_key, version_id: version_number, link: link, name: name})
    Versionarchive.create_archive_if_not_exist archive
  end

  def self.update_resource resource, product
    if resource && resource.crawled == false
      resource.crawled = true
      resource.language = product.language
      resource.prod_key = product.prod_key
      resource.save
    end
  end

  def self.set_release_date version, repository, tag
    date_string = GithubVersionCrawler.fetch_commit_date( repository.full_name, tag.commit.sha )
    return nil if date_string.to_s.empty?
    date_time   = DateTime.parse date_string
    version.released_string = date_string
    version.released_at = date_time
    version
  rescue => e
    self.logger.error "ERROR in set_release_date: #{e.message}"
    self.logger.error e.backtrace.join('\n')
    nil
  end

  def self.parse_version_number tag
    version_number = tag.name
    if version_number && version_number.match(/v[0-9]+\..*/)
      version_number.gsub!('v', '')
    end
    if version_number && version_number.match(/r[0-9]+\..*/)
      version_number.gsub!('r', '')
    end
    if version_number && version_number.match(/php\-[0-9]+\..*/)
      version_number.gsub!('php-', '')
    end
    if version_number && version_number.match(/PHP\_[0-9]+\..*/)
      version_number.gsub!('PHP_', '')
    end
    version_number
  end

  def self.create_or_update_github_link product, repository
    link = "https://github.com/#{repository.full_name}"
    Versionlink.create_project_link( product.language, product.prod_key, link, 'GitHub' )
  end

  def self.fetch_product repository, force_fullname = false
    return nil if repository.nil?

    repo_name = repository.name.to_s.downcase
    repo_name = repository.full_name.to_s.downcase if force_fullname

    language = substitute_language repository
    name     = substitude_name repo_name
    product  = Product.fetch_product language, name
    return product if product

    product  = Product.fetch_product language, repository.full_name
    return product if product

    Product.new({:prod_type => Project::A_TYPE_GITHUB, :language => language, :prod_key => repo_name})
  end

  def self.substitude_name name
    if name && name.eql?('php-src')
      return 'php'
    end
    name
  end

  def self.substitute_language repository
    language = repository.language
    language = 'none' if language.to_s.strip.empty?
    language = 'PHP' if repository.full_name.eql?('php/php-src')
    language
  end

  def self.update_product product, repository
    product.name          = repository.name
    product.name_downcase = repository.name.downcase
    product.description   = repository.description
    product.save
  end

  def self.crawle_object
    crawl = Crawle.new(crawler_name: 'GithubCrawler', crawler_version: '0.1.0')
    crawl.repository_src = "http://github.com"
    crawl.start_point = "/"
    crawl.exec_group = Time.now.strftime("%Y-%m-%d-%I-%M")
    crawl.save
    crawl
  end

end
