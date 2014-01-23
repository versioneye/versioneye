require 'crawler_task'
require 'github'

class BowerCrawler

  A_MINIMUM_RATE_LIMIT = 50
  A_MAX_RETRY = 12 # 12x10 ~> after that worker'll starve to death
  A_SLEEP_TIME = 20
  A_TASK_CHECK_EXISTENCE = "bower_crawler/check_existence"
  A_TASK_READ_PROJECT    = "bower_crawler/read_project"
  A_TASK_READ_VERSIONS   = "bower_crawler/read_versions"

  def self.logger
    ActiveSupport::BufferedLogger.new('log/bower.log')
  end

  @@rate_limits = nil

  def self.rate_limits(val = nil)
    @@rate_limits = val if val
    @@rate_limits
  end

  def self.github_rate_limit(token)
    Github.rate_limit(token)
  end

  #just for debugging to clear old noise
  def self.clean_all
    #remove all data added by crawler - only for devs.
    Product.where(prod_type: Project::A_TYPE_BOWER).delete_all
    Newest.where(prod_type: Project::A_TYPE_BOWER).delete_all
    License.where(language: Product::A_LANGUAGE_JAVASCRIPT).delete_all
    Dependency.where(language: Product::A_LANGUAGE_JAVASCRIPT).delete_all
    Versionlink.where(language: Product::A_LANGUAGE_JAVASCRIPT).delete_all
    Versionarchive.where(language: Product::A_LANGUAGE_JAVASCRIPT).delete_all
    CrawlerTask.delete_all
  end

  # token = GitHub user token
  def self.crawl(token, source_url = 'https://bower.herokuapp.com/packages', concurrent = true)
    crawl_concurrent(token, source_url) if concurrent
    crawl_serial(token, source_url) if not concurrent
  end

  def self.crawl_serial(token, source_url)
    logger.info "Using serial crawler - hopefully just for debugging."
    crawl_registered_list(source_url) # Filters out everything what is not on GitHub. If not on GitHub, skip it! And create tasks for the next crawler.
    crawl_existing_sources(token)     # Checks if the github url really exists! And create tasks for the next crawler.
    crawl_projects(token)             # Crawles bower.json file and creates/updates basic project infos in DB.
    crawl_versions(token)
  end

  def self.crawl_concurrent(token, source_url)
    logger.info "running Bower crawler on concurrent threads."
    tasks = []
    tasks << Thread.new {crawl_registered_list(source_url)}
    tasks << Thread.new {crawl_existing_sources(token)}
    tasks << Thread.new {crawl_projects(token)}
    tasks << Thread.new {crawl_versions(token)}
    tasks.each {|task| task.join}
  end

  def self.crawl_registered_list(source_url)
    content  = HTTParty.get(source_url)
    app_list = JSON.parse(content, symbolize_names: true)
    tasks    = 0

    if app_list.nil? or app_list.empty?
      logger.info "Error: cant read list of registered bower packages from: `#{source_url}`"
      return nil
    end

    app_list.each_with_index do |app, i|
      repo_info = url_to_repo_info(app[:url])
      if repo_info.nil? or repo_info.empty?
        # save non-supported url for further analyse
        task = to_existence_task({
          name: "not_supported",
          owner: "bower",
          fullname: app[:url],
          url: app[:url]
        })
        task.update_attributes({task_failed: true, url_exists: false})
        next
      else
        task = to_existence_task(repo_info)
        task.update_attributes({
          task_failed: false,
          re_crawl: true,
          url_exists: true
        })
        tasks += 1
      end
    end
    to_poison_pill(A_TASK_CHECK_EXISTENCE)
    logger.info "#-- Got #{tasks} registered libraries of Bower."
  end

  # checks does url of source exists or not
  def self.crawl_existing_sources(token)
    task_name = A_TASK_CHECK_EXISTENCE

    crawler_task_executor(task_name, token) do |task, token|
      result = check_repo_existence(task, token)
    end
  end

  def self.crawl_projects(token)
    task_name = A_TASK_READ_PROJECT
    crawler_task_executor(task_name, token) do |task, token|
      result = false
      check_request_limit(token)
      repo_response = Github.repo_info(task[:repo_fullname], token, true, task[:crawled_at])

      if repo_response.nil? or repo_response.is_a?(Boolean)
        logger.error "crawl_projects | Didnt get repo_info for #{task[:repo_fullname]}"
        next
      end

      if repo_response.code == 304
        logger.debug "crawl_projects | no changes for #{task[:repo_fullname]}, since #{task[:crawled_at]}"
        next
      end

      repo_info = nil
      unless repo_response.body.to_s.empty?
        repo_info = JSON.parse(repo_response.body, symbolize_names: true)
      else
        logger.error "Did not get any repo info for #{task[:repo_fullname]} - got: #{repo_response.code}"
      end

      if repo_response.code == 200 and not repo_info.nil?
        result = add_bower_package(task, repo_info,  token)
        if result == true
          task.update_attributes({crawled_at: DateTime.now})
          to_version_task(task) # add new version task when everything went oK
        end
      else
        logger.error "crawl_projects | cant read information for #{task[:repo_fullname]}."
      end
      sleep 1/100.0 # force little pause before next iteration
      result
    end
  end

  # imports package versions
  def self.crawl_versions(token)
    task_name = A_TASK_READ_VERSIONS
    result = false
    crawler_task_executor(task_name, token) do |task, token|
      tags = Github.repo_tags(task[:repo_fullname], token)
      if tags.nil? || tags.empty?
        logger.warn "`#{task[:repo_fullname]}` has no versions - going to skip."
        result = true
      else
        logger.info "#{task[:repo_fullname]} has #{tags.to_a.count} tags."
        prod_key = task[:repo_name].to_s.downcase
        product = Product.where(:prod_type => Project::A_TYPE_BOWER, :prod_key => prod_key).shift
        if product.nil?
          logger.error "#{task_name} | Cant find product for #{Project::A_TYPE_BOWER}/#{task[:repo_name]}"
          next
        end

        tags.each do |tag|
          parse_repo_tag( product, tag, token )
          sleep 1/100.0 # Just force little pause asking commit info -> github may block
        end

        #-- if product didnt get versionnumber from project-file
        if product[:version].nil?
          latest_version = product.sorted_versions.first
          product[:version] = latest_version[:version] if latest_version
        end
        result = true
      end
      result
    end
  end

  # using: task_executor(task_name) {|task_name| crawl_money}
  def self.crawler_task_executor(task_name, token)
    logger.info "#-- #{task_name} is starting ... "
    start_time = Time.now
    success = 0; failed = 0
    while true do
      check_request_limit(token)
      task = get_task_for(task_name)
      next if task.nil?

      if task[:poison_pill] == true
        task.remove
        logger.info "#-- #{task_name} got poison pill. Going to die ..."
        break
      end

      # Worker content
      if block_given?
        result = yield(task, token)
      else
        logger.info "Task executor got no execution block."
        break
      end

      # Return boolean in your block when want to update these metrics
      if result
        success += 1
        waited = 0
        task.update_attributes({
          crawled_at: DateTime.now,
          re_crawl: false,
          task_failed: false
        })
      else
        failed += 1
        task.update_attributes({
          task_failed: true,
          fails: task[:fails] + 1,
          re_crawl: false
        })
      end

      logger.info "#{task_name}| success: #{success} , failed: #{failed}"
    end

    unfinished = CrawlerTask.by_task(task_name).crawlable.count
    runtime    = Time.now - start_time
    logger.info "#-- #{task_name} is done in #{runtime} seconds. success: #{success}, failed: #{failed}, unfinished: #{unfinished}"
  rescue => ex
    logger.error ex.message
    logger.error ex.backtrace.join('\n')
  end


  def self.get_task_for(task_name)
    task = nil
    10.times do |i|
      task = CrawlerTask.by_task(task_name).crawlable.desc(:weight).shift
      break if task

      logger.info "No tasks for #{task_name} - going to wait #{A_SLEEP_TIME} seconds before re-trying again"
      sleep A_SLEEP_TIME
    end

    if task.nil?
      task = to_poison_pill(task_name)
    end
    task
  end

  def self.http_head(url, modified_since = nil)
    response = nil
    headers = nil
    if modified_since
      headers = {"If-Modified-Since" => modified_since.rfc822}
    end
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
      response = http.request_head(uri.path, headers)
    end
    response
  rescue => e
    logger.error "Cant check headers of url: `#{url}`. #{e.message}"
    logger.error e.backtrace.join('\n')
  end

  # TODO refactor. This method is to big.
  def self.check_repo_existence(task, token)
    success =  false
    repo_url = "https://github.com/#{task[:repo_fullname]}"
    response = http_head(repo_url)
    return false if response.nil? or response.is_a?(Boolean)

    response_code = response.code.to_i
    if response_code == 200
      read_task = to_read_task(task, task[:url])
      read_task.update_attributes({
        weight: 10,
        task_failed: false,
        url_exists: true,
        re_crawl: true
      })
      success = true
    elsif response_code == 301 or response_code == 308
      logger.info "#{task[:task]} | #{task[:repo_fullname]} has moved to #{response['location']}"
      # mark current task as failed and dont crawl it
      repo_info = url_to_repo_info(response['location'])
      task.update_attributes({
        re_crawl: false,
        url_exists: false
      })
      # create new task with new url and try again with new url
      task = to_existence_task(repo_info)
      task.update_attributes({
        weight: 20,
        task_failed: false,
        re_crawl: true,
        url_exists: true
      })
      success = true
    elsif response_code == 304
      logger.info "No changes for `#{task[:repo_fullname]}` since last crawling `#{read_task[:crawled_at]}`. Going to skip."
      task.update_attributes({url_exists: true, re_crawl: false})
      success = true
    elsif response_code == 404
      logger.error "check_repo_existence| 404 for #{task[:repo_fullname]} on `#{task[:url]}`"
    elsif response_code >= 500
      # when service down
      logger.error "check_repo_existence | Sadly Github is down; cant access #{task[:url]}"
      task.update_attributes({
        fails: task[:fails] + 1,
        re_crawl: true,
        task_failed: true,
      })
    end
    success
  end

  def self.add_bower_package(task, repo_info, token)
    logger.info "#-- reading #{task[:repo_fullname]} from url: #{task[:url]} branch: #{repo_info[:default_branch]}"
    pkg_file = self.read_project_file_from_github(task, token, repo_info[:default_branch])
    product  = nil
    product  = create_bower_package(pkg_file, repo_info, token) if pkg_file
    result   = false
    result   = true if product and product.save
    result
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join('\n')
    false
  end

  # Saves product and save sub/related docs
  def self.create_bower_package(pkg_info, repo_info, token)
    prod = create_or_update_product( pkg_info, repo_info )

    Versionlink.create_versionlink prod[:language], prod[:prod_key], prod[:version], pkg_info[:url], "SCM"
    Versionlink.create_versionlink prod[:language], prod[:prod_key], prod[:version], pkg_info[:homepage], "Homepage"

    to_dependencies(prod, pkg_info, :dependencies,     Dependency::A_SCOPE_COMPILE)
    to_dependencies(prod, pkg_info, :dev_dependencies, Dependency::A_SCOPE_DEVELOPMENT)

    pkg_info[:licenses].to_a.each { |lic| create_or_update_license( prod, lic ) }

    # TODO developers ??

    prod
  end

  def self.read_project_file_from_github(task, token, branch = 'master')
    owner    = task[:repo_owner]
    repo     = task[:repo_name]
    fullname = task[:repo_fullname]
    repo_url = task[:url]
    pkg_info = nil
    supported_files = Set.new ['bower.json', 'component.json', 'module.json']
    supported_files.to_a.each do |filename|
      file_url     = "https://raw.github.com/#{fullname}/#{branch}/#{filename}"
      project_file = read_project_file_from_url( file_url, token )
      if project_file.is_a?(Hash)
        logger.info "Found: #{filename} for #{task[:repo_fullname]}"
        pkg_info = to_pkg_info(owner, repo, repo_url, project_file)
        break
      end
    end

    if pkg_info.nil?
      logger.info "#{task[:repo_fullname]} has no supported project files. #{supported_files.to_a}"
    end

    pkg_info
  end

  def self.read_project_file_from_url(file_url, token)
    response = HTTParty.get( file_url )
    return nil if response.nil? or response.code != 200
    content  = JSON.parse(response.body, symbolize_names: true)
    return nil if content.nil?
    content
  rescue => e
    logger.error "Error: cant parse JSON file for #{file_url}. #{e.message}"
    logger.error e.backtrace.join('\n')
    nil
  end

  def self.parse_repo_tag(product, tag, token)
    if product.nil? or tag.nil?
      logger.error "method: parse_repo_tag(product, tag, token) - Product or tag cant be nil"
      return
    end

    tag = tag.deep_symbolize_keys
    tag_name = CrawlerUtils.remove_version_prefix( tag[:name].to_s )
    if tag_name.nil?
      logger.error "Skipped tag `#{tag_name}` "
      return
    end

    if product.version_by_number( tag_name )
      logger.info "#{product.prod_key} : #{tag_name} exists already"
      return
    end

    check_request_limit(token)
    add_new_version(product, tag_name, tag, token)

    CrawlerUtils.create_newest product, tag_name, logger
    CrawlerUtils.create_notifications product, tag_name, logger

    logger.info " -- Got package version #{product.prod_key} : #{tag_name} "

    url = "https://www.github.com/#{product[:prod_key]}"
    Versionlink.create_versionlink product.language, product.prod_key, tag_name, url, "Github"
    create_version_archive(product, tag_name, tag[:zipball_url]) if tag.has_key?(:zipball_url)
  end

  def self.add_new_version( product, tag_name, tag, token )
    new_version                 = Version.new version: tag_name
    new_version.released_string = release_date_string( tag, token )
    new_version.released_at     = released_date( new_version.released_string )
    product.versions << new_version
    product.reindex = true
    product.save
  end

  def self.release_date_string(tag, token)
    released_string = nil
    commit_info = Github.get_json(tag[:commit][:url], token)
    if commit_info
      released_string = commit_info[:commit][:committer][:date].to_s
    else
      logger.error "No commit info for tag `#{tag_name}` url: #{tag[:commit][:url]}"
    end
    released_string
  end

  def self.released_date( released_string )
    return nil if released_string.to_s.empty?
    released_string.to_datetime
  rescue => e
    logger.error e.backtrace.join('\n')
    nil
  end

  def self.check_request_limit(token)
    10.times do |i|
      break unless rate_limits.nil?
      val = github_rate_limit(token) #ask rate limits from API
      rate_limits(val)
      break unless rate_limits.nil?
      sleep A_SLEEP_TIME
    end

    if rate_limits.nil?  or not rate_limits.has_key?(:core)
      logger.error "Get no rate_limits from Github API - smt very bad is going on."
      sleep A_SLEEP_TIME
      return
    end

    @@rate_limits[:core][:remaining] -= 1
    limits = rate_limits[:core]
    time_left = (limits[:reset] - Time.now.to_i) / 60 #in minutes
    time_left += 1 #add additional minute for rounding errors and warming up
    if limits[:remaining] <= A_MINIMUM_RATE_LIMIT and time_left > 0
      logger.info "Remaining rate limits. #{limits}"
      logger.info "Going to stop crawling for next #{time_left} minutes"
      rate_limits(nil)
      sleep time_left.minutes
      logger.info "Waking up and going to continue crawling."
    end

    if (limits[:remaining] % 100) == 0 or limits[:remaining] < (A_MINIMUM_RATE_LIMIT + 10)
      val = github_rate_limit(token)
      rate_limits(val)
      logger.info "#-- Remaining request limits: #{limits}"
      sleep 1
    end
    rate_limits
  end

  def self.to_existence_task(repo_info)
    task = CrawlerTask.find_or_create_by(
      task: A_TASK_CHECK_EXISTENCE,
      repo_fullname: repo_info[:full_name]
    )

    task.update_attributes({
      repo_owner: repo_info[:owner],
      repo_name: repo_info[:repo],
      url: repo_info[:url],
      runs: task[:runs] + 1,
      re_crawl: true
    })

    task
  end

  def self.to_read_task(task, url)
    read_task = CrawlerTask.find_or_create_by(
      task: A_TASK_READ_PROJECT,
      repo_fullname: task[:repo_fullname]
    )

    read_task.update_attributes({
      runs: read_task[:runs] + 1,
      repo_name: task[:repo_name],
      repo_owner: task[:repo_owner],
      weight: 1 + task[:weight],
      url: url
    })

    read_task
  end

  def self.to_version_task(task)
    version_task = CrawlerTask.find_or_create_by(
      task: A_TASK_READ_VERSIONS,
      repo_name: task[:repo_name],
      repo_fullname: task[:repo_fullname]
    )

    version_task.update_attributes({
      runs: version_task[:runs] + 1,
      repo_name: task[:repo_name],
      repo_owner: task[:repo_owner],
      url: task[:url],
      url_exists: true,
      weight: 1,
      re_crawl: true
    })
    version_task
  end

  def self.to_poison_pill(task_name)
    task = CrawlerTask.find_or_create_by({task: task_name, poison_pill: true})
    task.update_attributes({
      re_crawl: true,
      url_exists: true,
      weight: -10  # will be the last when getting sorted list
    })
    task
  end

  def self.create_or_update_product( pkg_info, repo_info )
    prod = Product.find_or_create_by(
       prod_key: pkg_info[:name].to_s.downcase,
       prod_type: Project::A_TYPE_BOWER
    )
    language = Product::A_LANGUAGE_JAVASCRIPT
    language = repo_info[:language] unless repo_info[:language].nil?
    prod.update_attributes({
      language:      language,
      name:          pkg_info[:name].to_s,
      name_downcase: pkg_info[:name].to_s.downcase,
      version:       pkg_info[:version],
      private_repo:  pkg_info[:private_repo],
      description:   pkg_info[:description].to_s
    })
    prod.add_version pkg_info[:version]
    prod.save
    prod
  rescue => e
    logger.error e.backtrace.join('\n')
    nil
  end

  def self.create_version_archive(prod, version, url, name = nil)
    if name.nil?
      name = "#{prod[:name]}_#{version}.zip"
    end
    archive = Versionarchive.new({:language => prod[:language], :prod_key => prod[:prod_key],
      :version_id => version, :name => name, :link => url})
    Versionarchive.create_if_not_exist_by_name( archive )
  end

  def self.create_or_update_license(product, license_info)
    return nil if product.nil?

    new_license = License.find_or_create_by(
      language: product[:language],
      prod_key: product[:prod_key],
      version:  product[:version],
      name:     license_info[:name]
    )

    new_license.update_attributes({
      name: license_info[:name],
      url:  license_info[:url]
    })
    new_license
  end

  def self.to_dependencies(prod, pkg_info, key, scope = Dependency::A_SCOPE_COMPILE)
    return nil if prod.nil? || !pkg_info.has_key?(key) || pkg_info[key].nil? || pkg_info[key].empty?

    deps = []
    if not pkg_info[key].is_a?(Hash)
      logger.error "#{prod[:prod_key]} dependencies have wrong structure. `#{pkg_info[key]}`"
      return nil
    end

    pkg_info[key].each_pair do |prod_name, version|
      next if prod_name.to_s.strip.empty?
      dep = to_dependency(prod, prod_name, version, scope)
      deps << dep if dep
    end
    deps
  end

  def self.to_dependency(prod, dep_name, dep_version, scope = Dependency::A_SCOPE_COMPILE)
    dependency = Dependency.find_or_create_by(
      prod_type: Project::A_TYPE_BOWER,
      language: prod[:language],
      prod_key: prod[:prod_key].to_s.downcase,
      prod_version: prod[:version],
      dep_prod_key: dep_name
    )
    dependency.update_attributes({
      name: dep_name,
      version: dep_version, # TODO: It can be that the version is in the bower.json is a git tag / path
      scope: scope
    })
    dependency.update_known
    dependency
  rescue => e
    logger.error "Error: Cant save dependency `#{dep_name}` with version `#{dep_version}` for #{prod[:prod_key]}. -- #{e.message}"
    logger.error e.backtrace.join('\n')
    nil
  end

  def self.to_pkg_info(owner, repo, project_url, project_info)
    pkg_name = project_info[:name].to_s.strip
    pkg_name = repo if pkg_name.empty?

    pkg_info = {
      name: pkg_name,
      group_id: owner,
      artifact_id: repo,
      full_name: "#{owner}/#{repo}",
      version: project_info[:version],
      licenses: [{name: "unknown", url: nil}], # default values, try to read real values later.
      description: project_info[:description],
      dependencies: project_info[:dependencies],
      dev_dependencies: project_info[:devDependencies],
      homepage: project_info[:homepage],
      url: project_url,
      private_repo: false,
    }

    if project_info.has_key?(:license)
      read_license pkg_info, project_info
    elsif project_info.has_key?(:licenses)
      read_licenses pkg_info, project_info
    end

    pkg_info
  end

  def self.read_license(info, project_info)
    license_info = project_info[:license]
    if license_info.is_a?(String)
      info[:licenses] = [{name: license_info, url: nil}]
    elsif license_info.is_a?(Array)
      info[:licenses] = []
      license_info.each do |lic|
        if lic.is_a?(String)
          info[:licenses] << {name: lic, url: nil}
        elsif lic.is_a?(Hash)
          info[:licenses] << {name: lic[:type], url: lic[:url]}
        end
      end
    end
  end

  def self.read_licenses(info, project_info)
    # support for npm.js licenses
    info[:licenses] = []
    if project_info[:licenses].is_a?(Array)
      project_info[:licenses].to_a.each do |lic|
        if lic.is_a?(String)
          info[:licenses] << {name: lic, url: nil}
        else lic.is_a?(Hash)
          info[:licenses] << {name: lic[:type], url: lic[:url]}
        end
      end
    elsif project_info[:licenses].is_a?(Hash)
      lic = project_info[:licenses]
      info[:licenses] << {name: lic[:type], url: lic[:url]}
    end
  end

  def self.url_to_repo_info(repo_url)
    git_url_matcher = /github.com/i
    git_io_matcher = /\w+\.github\.[io|com]/i
    urlpath = repo_url.gsub(/:\/+|\/+|\:/, "|")

    if repo_url =~ git_io_matcher
      _, owner, repo, _ = urlpath.split('|')
      owner = owner.split('.').first
    elsif repo_url =~ git_url_matcher
      _, _, owner, repo = urlpath.split('|')
    else
      # TODO: add support for private hosts
      logger.info "warning: going to ignore #{repo_url} - its not github repo, cant read bower.json"
      return nil
    end

    repo.to_s.gsub!(/\.git$/, "")
    repo_name = "#{owner}/#{repo}"

    {
      owner: owner,
      repo: repo,
      full_name: repo_name,
      url: repo_url
    }
  end

end
