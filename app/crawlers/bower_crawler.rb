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
  def self.crawl(token, source_url = nil, concurrent = true)
    if source_url.to_s.strip.empty?
      source_url = "https://bower.herokuapp.com/packages"
      logger.info "Going to use default url: `#{source_url}`"
    end

    if concurrent
      crawl_concurrent(token, source_url)
    else
      crawl_serial(token, source_url)
    end
  end

  #for debugging
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
    logger.info "All task of Bower crawler are finished now. Have a good day!"
  end

  def self.crawl_registered_list(source_url)
    #fetches list of all registered bower packages
    content = HTTParty.get(source_url)
    app_list = JSON.parse(content, symbolize_names: true)
    tasks = 0

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

  #checks does url of source exists or not
  def self.crawl_existing_sources(token)
    task_name = A_TASK_CHECK_EXISTENCE

    crawler_task_executor(task_name, token) do |task, token|
      result = check_repo_existence(task, token)
    end
  end

  # Imports information of existing project file
  def self.crawl_projects(token)
    task_name = A_TASK_READ_PROJECT
    crawler_task_executor(task_name, token) do |task, token|
      result = false
      check_request_limit(token)
      repo_response = Github.repo_info(task[:repo_fullname], token, true, task[:crawled_at])
     
      if repo_response.nil? or repo_response.is_a?(Boolean)
        logger.error "crawl_projects | Didnt get repo_info for #{task[:repo_fullname]}"
        next #drop this task and take a new
      end

      if repo_response.code == 304
        logger.debug "crawl_projects | no changes for #{task[:repo_fullname]}, since #{task[:crawled_at]}"
        next
      end

      repo_info = nil
      unless repo_response.body.to_s.empty?
        repo_info = JSON.parse(repo_response.body, symbolize_names: true)
      else
        logger.error "Didnt get any repo info for #{task[:repo_fullname]} - got: #{repo_response.code}"
      end

      if repo_response.code == 200 and not repo_info.nil?
        result = add_bower_package(task, repo_info,  token)
        if result == true
          task.update_attributes({crawled_at: DateTime.now})
          to_version_task(task) # add new version task when everything went oK
        end
      elsif repo_response.code == 304
        logger.info "crawl_projects | #{task[:repo_fullname]} has no changes; going to skip it;"
        result = true
      else
        logger.error "crawl_projects | cant read information for #{task[:repo_fullname]}."
      end
      sleep 1/100.0 # force little pause before next iteration
      result
    end
  end

  #imports package versions
  def self.crawl_versions(token)
    task_name = A_TASK_READ_VERSIONS
    result = false
    crawler_task_executor(task_name, token) do |task, token|
      tags = Github.repo_tags(task[:repo_fullname], token)
      if tags.nil?
        logger.warn "`#{task[:repo_fullname]}` has no versions - going to skip."
        result = false
      else
        logger.info "#{task[:repo_fullname]} has #{tags.to_a.count} tags."
        prod_key = task[:repo_fullname].to_s.downcase
        prod = Product.where(:prod_type => Project::A_TYPE_BOWER, :prod_key => prod_key).shift
        if prod.nil?
          logger.error "#{task_name} | Cant find product for #{Project::A_TYPE_BOWER}/#{task[:repo_fullname]}"
          next
        end

        tags.each do |tag|
          parse_repo_tag(prod, tag, token)
          sleep 1/100 # Just force little pause asking commit info -> github may block
        end

        #-- if prod didnt get versionnumber from project-file
        if prod[:version].nil?
          latest_version = prod.sorted_versions.first
          prod[:version] = latest_version[:version] if latest_version
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

  def self.check_repo_existence(task, token)
    success =  false
    repo_url = "https://github.com/#{task[:repo_fullname]}"
    response = http_head(repo_url)
    return false if response.nil? or response.is_a?(Boolean)

    response_code  = response.code.to_i
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
      #mark current task as failed and dont crawl it
      repo_info = url_to_repo_info(response['location'])
      task.update_attributes({
        re_crawl: false,
        url_exists: false
      })
      #create new task with new url and try again with new url
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
      #when service down
      logger.error "check_repo_existence | Sadly Github is down; cant access #{task[:url]}"
      task.update_attributes({
        fails: task[:fails] + 1,
        re_crawl: true,
        task_failed: true,
      })
    end

    return success
  end

  def self.add_bower_package(task, repo_info, token)
    logger.info "#-- reading #{task[:repo_fullname]} from url: #{task[:url]} branch: #{repo_info[:default_branch]}"

    pkg_file = self.read_project_file_from_github(task, token, repo_info[:default_branch])
    result   = false
    product  = nil
    product  = create_bower_package(pkg_file, repo_info, token) if pkg_file
    result = true if product and product.save
    result
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join('\n')
    false
  end

  # Saves product and save sub/related docs
  def self.create_bower_package(pkg_info, repo_info, token)
    prod = to_product(pkg_info)
    prod[:version] = pkg_info[:version]
    prod.add_version pkg_info[:version]
    prod[:language] = repo_info[:language] unless repo_info[:language].nil?

    to_version_link(prod, prod[:version], pkg_info[:url])

    pkg_info[:licenses].to_a.each {|lic| to_license(prod, lic)}

    deps = to_dependencies(prod, pkg_info)
    deps.to_a.each {|dep| prod.dependencies << dep}
    deps = to_dev_dependencies(prod, pkg_info)
    deps.to_a.each {|dep| prod.dependencies << dep}

    prod
  end

  def self.read_project_file_from_github(task, token, branch = "master")
    pkg_info = nil
    supported_files = Set.new ['bower.json', 'component.json', 'module.json', 'package.json']

    owner = task[:repo_owner]
    repo = task[:repo_name]
    fullname = task[:repo_fullname]
    repo_url = task[:url]
    supported_files.to_a.each do |filename|
      file_url = "https://raw.github.com/#{fullname}/#{branch}/#{filename}"
      project_file = read_project_file_from_url(file_url, token)
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

  def self.parse_repo_tag(prod, tag, token)
    if prod.nil? or tag.nil?
      logger.error "method: parse_repo_tag(prod, tag, token) - Product or tag cant be nil"
      return
    end
    tag = tag.deep_symbolize_keys
    bower_parser = BowerParser.new
    tag_name = tag[:name].to_s
    if tag_name && tag_name.match(/v[0-9]+\..*/)
      tag_name.gsub!('v', '')
    end
    # tag_name = bower_parser.cleanup_version(tag_name)
    # m = tag_name.match bower_parser.rules[:full_version]

    if tag_name.nil?
      logger.error "Skipped tag `#{tag_name}` "
      return
    end

    check_request_limit(token)

    commit_info = Github.get_json(tag[:commit][:url], token) # TODO @reiz check if it is the right commit and the right date!
    unless commit_info.nil?
      released_at = commit_info[:commit][:committer][:date].to_s.to_datetime
    else
      logger.error "No commit info for tag `#{tag_name}` url: #{tag[:commit][:url]}"
      released_at = nil
    end

    if prod.version_by_number(tag_name).nil?
      #add version only if there's no version with same label

      new_version = Version.new version: tag_name, released_at: released_at
      prod.versions << new_version

      newest = to_newest(prod, tag_name)

      logger.info "Added version `#{new_version[:version]}` with release_date `#{new_version[:released_at]}`"
    end

    if tag.has_key?(:zipball_url)
      to_version_archive(prod, tag_name, tag[:zipball_url])
    end

    url = "https://www.github.com/#{prod[:prod_key]}"
    to_version_link(prod, tag_name, url, "Github")
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

  def self.to_newest(prod, version)
    newest = Newest.find_or_create_by(
      prod_key: prod[:prod_key],
      language: prod[:language],
      version: version
    )

    newest.update_attributes({
      name: prod[:name],
      version: version,
      prod_type: Project::A_TYPE_BOWER
    })
    newest
  rescue => e
    logger.info "Cant save newest: #{newest.to_json}.\n #{e.message} \n #{e.backtrace.join('\n')}"
  end


  def self.to_product(pkg_info)
    prod = Product.find_or_create_by(
       prod_key: pkg_info[:full_name].to_s.downcase,
       prod_type: Project::A_TYPE_BOWER
    )

    language = Product::A_LANGUAGE_JAVASCRIPT
    prod.update_attributes({
      name: pkg_info[:name].to_s,
      name_downcase: pkg_info[:name].to_s.downcase,
      language: language,
      private_repo: pkg_info[:private_repo],
      description: pkg_info[:description].to_s
    })
    # TODO @reiz check if it makes sense to create project links here.
    prod
  end

  def self.to_version_link(prod, version, url, link_name = "SCM")
    new_link = Versionlink.find_or_create_by(
      language: prod[:language],
      prod_key: prod[:prod_key],
      version_id: version,
      name: link_name
    )
    new_link.update_attributes({
      link: url,
      name: link_name
    })
    new_link
  end

  def self.to_version_archive(prod, version, url, name = nil)
    if name.nil?
      name = "#{prod[:name]}_#{version}.zip"
    end
    new_link = Versionarchive.find_or_create_by(
      language: prod[:language],
      prod_key: prod[:prod_key],
      version_id: version,
      name: name
    )
    new_link.update_attributes({
      link: url,
      name: name
    })

    new_link
  end

  def self.to_license(product, license_info)
    return nil if product.nil?

    new_license = License.find_or_create_by(
      language: product[:language],
      prod_key: product[:prod_key],
      version: product[:version],
      name: license_info[:name]
   )

    new_license.update_attributes({
      name: license_info[:name],
      url: license_info[:url]
    })
    new_license
  end

  def self.to_dependencies(prod, pkg_info)
    return nil if prod.nil? || !pkg_info.has_key?(:dependencies) || pkg_info[:dependencies].nil? || pkg_info[:dependencies].empty?

    deps = []
    if not pkg_info[:dependencies].is_a?(Hash)
      logger.error "#{prod[:prod_key]} dependencies have wrong structure. `#{pkg_info[:dependencies]}`"
      return nil
    end

    pkg_info[:dependencies].each_pair do |prod_name, version|
      next if prod_name.to_s.strip.empty?
      dep = to_dependency(prod, prod_name, version)
      deps << dep if dep
    end
    deps
  end

  def self.to_dev_dependencies(prod, pkg_info)
    return nil if !pkg_info.has_key?(:dev_dependencies) or pkg_info[:dev_dependencies].nil? or pkg_info[:dev_dependencies].empty?

    deps = []
    if not pkg_info[:dev_dependencies].is_a?(Hash)
      logger.info "DevDependecies for #{prod[:prod_key]} have wrong structure. `#{pkg_info[:dev_dependencies]}`"
      return nil
    end

   pkg_info[:dev_dependencies].each_pair do |prod_name, version|
      next if prod_name.to_s.empty?
      dep = to_dependency(prod, prod_name, version, Dependency::A_SCOPE_DEVELOPMENT)
      deps << dep if dep
    end
    deps
  end

  def self.to_dependency(prod, dep_name, dep_version, scope = nil)
    unless scope
      scope = Dependency::A_SCOPE_REQUIRE
    end

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

    dependency
  rescue => e
    logger.error "Error: Cant save dependency `#{dep_name}` with version `#{dep_version}` for #{prod[:prod_key]}."
    logger.error e.message
    logger.error e.backtrace.join('\n')
    nil
  end

  def self.to_pkg_info(owner, repo, project_url, project_info)
    pkg_name = project_info[:name].to_s.strip
    if pkg_name.empty?
      pkg_name  = repo
    end

    info = {
      name: pkg_name,
      group_id: owner,
      artifact_id: repo,
      full_name: "#{owner}/#{repo}",
      version: project_info[:version],
      licenses: [{name: "unknown", url: nil}],
      description: project_info[:description],
      dependencies: project_info[:dependencies],
      dev_dependencies: project_info[:devDependencies],
      url: project_url,
      private_repo: false,
    }

    if project_info.has_key?(:license)
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
    elsif project_info.has_key?(:licenses)
      #support for npm.js licenses
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

    info
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
      #TODO: add support for private hosts
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
