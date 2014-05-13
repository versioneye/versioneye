# require 'crawler_task'
# require 'github'

class BowerCrawler

  A_MINIMUM_RATE_LIMIT = 50
  A_MAX_RETRY = 12 # 12x10 ~> after that worker'll starve to death
  A_SLEEP_TIME = 20
  A_TASK_CHECK_EXISTENCE = "bower_crawler/check_existence"
  A_TASK_READ_PROJECT    = "bower_crawler/read_project"
  A_TASK_READ_VERSIONS   = "bower_crawler/read_versions"
  A_TASK_TAG_PROJECT     = "bower_crawler/tag_project"

  def self.logger
    ActiveSupport::BufferedLogger.new('log/bower.log')
  end

  @@rate_limits = nil

  def self.rate_limits(val = nil)
    @@rate_limits = val if val
    @@rate_limits
  end

  def self.github_rate_limit(token)
    OctokitApi.client(token).rate_limit
  end

  # Just for debugging to clear old noise
  def self.clean_all
    # Remove all data added by crawler - only for devs.
    Product.where(prod_type: Project::A_TYPE_BOWER).delete_all
    Newest.where(prod_type: Project::A_TYPE_BOWER).delete_all
    Dependency.where(language: Product::A_LANGUAGE_JAVASCRIPT).delete_all
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
    crawl_tag_project(token)
  end

  def self.crawl_concurrent(token, source_url)
    logger.info "running Bower crawler on concurrent threads."
    tasks = []
    tasks << Thread.new {crawl_registered_list(source_url)}
    tasks << Thread.new {crawl_existing_sources(token)}
    tasks << Thread.new {crawl_projects(token)}
    tasks << Thread.new {crawl_versions(token)}
    tasks << Thread.new {crawl_tag_project(token)}

    tasks.each {|task| task.join}
  end

  def self.crawl_registered_list(source_url)
    response = HTTParty.get(source_url)
    app_list = JSON.parse(response.body, symbolize_names: true)
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
        task.update_attributes!({task_failed: true, url_exists: false})
        next
      else
        repo_info[:registry_name] = app[:name]
        task = to_existence_task(repo_info)
        task.update_attributes!({
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
        logger.error "crawl_projects | Did not get repo_info for #{task[:repo_fullname]}"
        next
      end

      if repo_response.code == 304
        logger.debug "crawl_projects | no changes for #{task[:repo_fullname]}, since #{task[:crawled_at]}"
        next
      end

      if repo_response.body.to_s.empty?
        logger.error "Did not get any repo info for #{task[:repo_fullname]} - got: #{repo_response.code}"
        next
      end

      repo_info = JSON.parse(repo_response.body, symbolize_names: true)
      if repo_info.nil? || repo_response.code != 200
        logger.error "crawl_projects | cant read information for #{task[:repo_fullname]}."
        next
      end

      repo_info[:repo_fullname] = task[:repo_fullname]
      product = add_bower_package(task, repo_info,  token)
      if product.nil?
        logger.error "crawl_projects | cant add bower package for #{task[:repo_fullname]}."
        next
      end

      task.update_attributes({crawled_at: DateTime.now})
      to_version_task(task, product[:prod_key]) # add new version task when everything went oK
      sleep 1/100.0 # force little pause before next iteration
      true
    end
  end

  # imports package versions
  def self.crawl_versions(token)
    task_name = A_TASK_READ_VERSIONS
    result = false
    crawler_task_executor(task_name, token) do |task, token|
      prod_key = make_prod_key(task)
      product  = Product.fetch_bower task[:registry_name]
      if product.nil?
        logger.error "#{task_name} | Cant find product for #{task[:repo_fullname]} with prod_key #{prod_key}"
        next
      end

      tags = Github.repo_tags(task[:repo_fullname], token)
      if tags.nil? || tags.empty?
        logger.warn "`#{task[:repo_fullname]}` has no versions - going to skip."
        if product.version.to_s.empty?
          product.remove
        end
        result = true
      else
        tags_count = tags.to_a.count
        logger.info "#{task[:repo_fullname]} has #{tags_count} tags."
        if product.versions && product.versions.count == tags_count
          logger.info "-- skip #{task[:repo_fullname]} because tags count (#{tags_count}) is equal to versions.count."
        end

        tags.each do |tag|
          parse_repo_tag( task[:repo_fullname], product, tag, token )
          to_tag_project_task(task, tag)
          sleep 1/100.0 # Just force little pause asking commit info -> github may block
        end

        latest_version = product.sorted_versions.first
        if latest_version
          product[:version] = latest_version[:version]
          product.save
          update_product_dependencies(product, latest_version[:version])
        end
        result = true
      end
      result
    end
  end

  def self.crawl_tag_project(token)
    task_name = A_TASK_TAG_PROJECT
    result = false
    crawler_task_executor(task_name, token) do |task, token|
      tag_name = task[:tag_name]
      commit_info = task[:data].deep_symbolize_keys
      repo_name = task[:repo_fullname]

      logger.debug "#-- going to read project deps for #{repo_name} with `#{tag_name}`"
      commit_tree  = fetch_commit_tree(commit_info[:url], token)
      next if commit_tree.nil?

      project_info = fetch_project_info_by_sha(repo_name, commit_tree[:sha], token, tag_name)
      next if project_info.nil?

      project_file = fetch_project_file(repo_name, project_info[:url], token)
      next if project_file.nil?

      file_content = parse_json(project_file)
      next if file_content.nil? or file_content.is_a?(TrueClass)

      unless file_content.has_key?(:version)
        logger.warn "No version found in project file on tag #{tag_name} of #{repo_name}. Going to use tag."
        cleaned_tag = CrawlerUtils.remove_version_prefix( tag_name.to_s )
        file_content[:version] = cleaned_tag
      end

      pkg_info = to_pkg_info(task[:owner], task[:repo], project_info[:url], file_content)
      prod = Product.fetch_bower(task[:registry_name])
      to_dependencies(prod, pkg_info, :dependencies,     Dependency::A_SCOPE_REQUIRE)
      to_dependencies(prod, pkg_info, :dev_dependencies, Dependency::A_SCOPE_DEVELOPMENT)

      result =  true
    end
  end

  def self.parse_json(doc)
    JSON.parse doc, symbolize_names: true
  rescue => e
    logger.error "cant parse doc: #{doc} \n #{e.message}"
  end

  #reads information of commit data, which includes link to commit tree
  def self.fetch_commit_tree(commit_url, token)
    check_request_limit(token)
    uri = URI(commit_url)
    data = Github.get_json(uri.path, token)
    if data.nil?
      logger.error "fetch_commit_tree | cant read commit information on #{commit_url}"
    end
    data
  end

  def self.fetch_project_info_by_sha(repo_name, sha, token, tag = nil)
    check_request_limit(token)
    project_files = Github.project_files_from_branch(repo_name, token, sha)
    if project_files.nil?
      logger.error "Didnt get any supported project file for #{repo_name} on the tag sha: `#{sha}`"
      return
    end

    bower_files = project_files.keep_if do |file|
      ProjectService.type_by_filename(file[:path]) == Project::A_TYPE_BOWER
    end

    logger.info "-- Found #{bower_files.count} bower files for #{repo_name} #{tag}"
    bower_files.first
  end

  def self.fetch_project_file(repo_name, project_url, token)
    logger.debug "Reading tag_project file for #{repo_name}: #{project_url}"
    file_data = Github.fetch_file(project_url, token)
    if file_data.nil?
      logger.error "cant read content of project file for #{repo_name}: #{project_url}"
      return
    end

    Base64.decode64(file_data[:content])
  end

  #add latest version for dependencies missing prod_version
  def self.update_product_dependencies(product, version_label)
    all_dependencies = Dependency.where(prod_key: product[:prod_key])
    deps_without_version = all_dependencies.keep_if {|dep| dep[:prod_key].nil? }
    deps_without_version.each do |dep|
        dep[:prod_version] = product[:version]
        dep.save
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
    success  = false
    repo_url = "https://github.com/#{task[:repo_fullname]}"
    response = http_head(repo_url)
    return false if response.nil? or response.is_a?(Boolean)

    response_code = response.code.to_i
    if response_code == 200
      read_task = to_read_task(task, task[:url])
      read_task.update_attributes({
        registry_name: task[:registry_name], #registered name on bower.io, not same as github repo and projectfile
        weight: 10
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
      redirected_task = to_existence_task(repo_info)
      redirected_task.update_attributes({
        registry_name: task[:registry_name], #registered name on bower.io, not same as github repo and projectfile
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
    if pkg_file.nil?
      logger.error "add_bower_package | Didnt get any project file for #{task[:repo_fullname]}"
      return nil
    end

    pkg_file[:repo_fullname] = repo_info[:repo_fullname]
    pkg_file[:name] = task[:registry_name]  if task.has_attribute?(:registry_name) # if task has prod_key then use it - dont trust user's unvalidated bower.json
    pkg_file[:name] = repo_info[:name]      if pkg_file[:name].to_s.strip.empty?
    pkg_file[:name] = repo_info[:full_name] if pkg_file[:name].to_s.strip.empty?
    prod_key        = make_prod_key(task)
    product         = create_bower_package(prod_key, pkg_file, repo_info, token)
    if product.nil?
      logger.error "add_bower_package | cant create_or_find product for #{task[:repo_fullname]}"
      return nil
    end

    product.save!
    product
  rescue => e
    logger.error "add_bower_package | cant save product for #{repo_info}: #{product.errors.full_messages.to_sentence} - e.message"
    logger.error e.backtrace.join('\n')
    nil
  end

  # Saves product and save sub/related docs
  def self.create_bower_package(prod_key, pkg_info, repo_info, token)
    prod = create_or_update_product(prod_key, pkg_info, token, repo_info[:language])

    Versionlink.create_project_link prod[:language], prod[:prod_key], "https://github.com/#{repo_info[:repo_fullname]}", "SCM"
    Versionlink.create_project_link prod[:language], prod[:prod_key], pkg_info[:homepage], "Homepage"

    to_dependencies(prod, pkg_info, :dependencies,     Dependency::A_SCOPE_REQUIRE)
    to_dependencies(prod, pkg_info, :dev_dependencies, Dependency::A_SCOPE_DEVELOPMENT)

    pkg_info[:licenses].to_a.each { |lic| create_or_update_license( prod, lic ) }

    prod
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join('\n')
    nil
  end

  def self.read_project_file_from_github(task, token, branch = 'master')
    owner    = task[:repo_owner]
    repo     = task[:repo_name]
    fullname = task[:repo_fullname]
    repo_url = task[:url]
    pkg_info = nil
    supported_files = Set.new ['bower.json', 'component.json', 'module.json', 'package.json']
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
    return nil if response.nil? || response.code != 200

    content  = JSON.parse(response.body, symbolize_names: true)
    return nil if content.nil?

    content
  rescue => e
    logger.error "Error: cant parse JSON file for #{file_url}. #{e.message}"
    logger.error e.backtrace.join('\n')
    nil
  end

  def self.parse_repo_tag(repo_fullname, product, tag, token)
    if product.nil? or tag.nil?
      logger.error "-- parse_repo_tag(repo_fullname, product, tag, token) - Product or tag cant be nil"
      return
    end

    tag = tag.deep_symbolize_keys
    tag_name = CrawlerUtils.remove_version_prefix( tag[:name].to_s )
    if tag_name.nil?
      logger.error "-- Skipped tag `#{tag_name}` "
      return
    end

    if product.version_by_number( tag_name )
      logger.info "-- #{product.prod_key} : #{tag_name} exists already"
      return
    end

    add_new_version(product, tag_name, tag, token)
    CrawlerUtils.create_newest product, tag_name, logger
    CrawlerUtils.create_notifications product, tag_name, logger

    logger.info " -- Added version `#{product.prod_key}` : #{tag_name} "
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
    check_request_limit(token) #every func that calls Github api should check ratelimit first;
    commit_info = Github.get_json(tag[:commit][:url], token)
    if commit_info
      released_string = commit_info[:commit][:committer][:date].to_s
    else
      logger.error "No commit info for tag `#{tag}`"
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
      val = github_rate_limit(token) #ask rate limit from API
      rate_limits(val)
      break unless rate_limits.nil?
      sleep A_SLEEP_TIME
    end

    if rate_limits.nil?
      logger.error "Get no rate_limits from Github API - smt very bad is going on."
      sleep A_SLEEP_TIME
      return
    end

    @@rate_limits[:remaining] -= 1
    limit = rate_limits[:limit]
    time_left = (rate_limits[:resets_in] - Time.now.to_i) / 60 #in minutes
    time_left += 1 #add additional minute for rounding errors and warming up
    if limit <= A_MINIMUM_RATE_LIMIT and time_left > 0
      logger.info "Remaining rate limit. #{limit}"
      logger.info "Going to stop crawling for next #{time_left} minutes"
      rate_limits(nil)
      sleep time_left.minutes
      logger.info "Waking up and going to continue crawling."
    end

    if (limit % 100) == 0 or limit < (A_MINIMUM_RATE_LIMIT + 10)
      val = github_rate_limit(token)
      rate_limits(val)
      logger.info "#-- Remaining request limit: #{limit}"
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
      registry_name: repo_info[:registry_name],
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
      registry_name: task[:registry_name],
      weight: 1 + task[:weight].to_i,
      url_exists: true,
      re_crawl: true,
      url: url
    })

    read_task
  end

  def self.to_version_task(task, prod_key)
    version_task = CrawlerTask.find_or_create_by(
      task: A_TASK_READ_VERSIONS,
      prod_key: prod_key,
      repo_fullname: task[:repo_fullname]
    )

    version_task.update_attributes({
      runs: version_task[:runs] + 1,
      repo_name: task[:repo_name],
      repo_owner: task[:repo_owner],
      registry_name: task[:registry_name],
      url: task[:url],
      url_exists: true,
      weight: 1,
      re_crawl: true
    })
    version_task
  end

  def self.to_tag_project_task(task, tag)
    tag_task = CrawlerTask.find_or_create_by(
      task: A_TASK_TAG_PROJECT,
      repo_fullname: task[:repo_fullname],
      tag_name: tag[:name]
    )

    tag_task.update_attributes({
      runs: tag_task[:runs] + 1,
      repo_name: task[:repo_name],
      repo_owner: task[:repo_owner],
      registry_name: task[:registry_name],
      tag_name: tag[:name],
      data: tag[:commit],
      url: tag[:commit][:url],
      url_exists: true,
      weight: 10,
      re_crawl: true
    })

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

  def self.make_prod_key(task_info)
    "#{task_info[:repo_owner]}/#{task_info[:registry_name]}".strip.downcase
  end

  def self.create_or_update_product(prod_key, pkg_info, token, language = nil)
    language = Product::A_LANGUAGE_JAVASCRIPT if language.nil?
    prod     = Product.find_or_create_by( prod_key: prod_key, language: language )
    prod.update_attributes!(
      language:      language,
      prod_type:     Project::A_TYPE_BOWER,
      name:          pkg_info[:name].to_s,
      name_downcase: pkg_info[:name].to_s.downcase,
      private_repo:  pkg_info[:private_repo],
      description:   pkg_info[:description].to_s
    )
    set_version(prod, pkg_info, token)
    prod.save!
    prod
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join('\n')
    nil
  end

  def self.set_version prod, pkg_info, token
    tags = Github.repo_tags(pkg_info[:repo_fullname], token)
    version_exist_in_file = pkg_info.has_key?(:version) && !pkg_info[:version].to_s.strip.empty?
    no_tags_released = tags.nil? || tags.empty?
    if version_exist_in_file && no_tags_released
      prod.version = pkg_info[:version]
    end
    prod
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
    return nil if license_info[:name].nil? || license_info[:name].empty?

    new_license = License.find_or_create_by(
      language: product[:language],
      prod_key: product[:prod_key],
      version:  product[:version],
      name:     license_info[:name]
    )

    new_license.update_attributes!({
      name: license_info[:name],
      url:  license_info[:url]
    })
    new_license
  end

  def self.to_dependencies(prod, pkg_info, key, scope = nil)
    return nil if prod.nil? || !pkg_info.has_key?(key) || pkg_info[key].nil? || pkg_info[key].empty?

    deps = []
    if not pkg_info[key].is_a?(Hash)
      logger.error "#{prod[:prod_key]} dependencies have wrong structure. `#{pkg_info[key]}`"
      return nil
    end

    prod_version = fetch_version_for_dep(prod, pkg_info) # TODO refactor it, give as param.
    pkg_info[key].each_pair do |prod_name, version|
      next if prod_name.to_s.strip.empty?
      dep = to_dependency(prod, prod_version, prod_name, version, scope)
      deps << dep if dep
    end
    deps
  end

  def self.fetch_version_for_dep prod, pkg_info
    prod_version = pkg_info[:version]
    if prod_version.to_s.empty?
      prod_version = prod.sorted_versions.first.to_s
    end
    prod_version
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join('\n')
    nil
  end

  def self.to_dependency(prod, prod_version, dep_name, dep_version, scope = Dependency::A_SCOPE_REQUIRE)
    dep_prod = Product.fetch_bower(dep_name)
    dep_prod_key = nil
    dep_prod_key = dep_prod.prod_key if dep_prod
    dependency = Dependency.find_or_create_by(
      prod_type: Project::A_TYPE_BOWER,
      language: prod[:language],
      prod_key: prod[:prod_key].to_s,
      prod_version: prod_version,
      dep_prod_key: dep_prod_key,
      name: dep_name
    )
    dependency.update_attributes!({
      dep_prod_key: dep_prod_key,
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
    if (repo_url =~ /github.com\//i).nil?
      return nil
    end
    parts = repo_url.split("/")
    owner = parts[parts.length - 2]
    repo  = parts[parts.length - 1]
    if repo =~ /\.git$/i
      repo = repo.gsub(/\.git$/i, '')
    end
    full_name = "#{owner}/#{repo}"

    {
      owner: owner,
      repo: repo,
      full_name: full_name,
      url: repo_url
    }
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join('\n')
    nil
  end

end
