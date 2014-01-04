require 'crawler_task'
require 'github'

class BowerCrawler

  A_MINIMUM_RATE_LIMIT = 50 
  A_MAX_RETRY = 12 #12x10 ~> after that worker'll starve to death
  A_SLEEP_TIME = 20
  A_TASK_CHECK_EXISTENCE = "bower_crawler/check_existence"
  A_TASK_READ_PROJECT = "bower_crawler/read_project"
  A_TASK_READ_VERSIONS    = "bower_crawler/read_versions"
  
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

  def self.crawl(token, source_url = nil, concurrent = true)
    if source_url.to_s.strip.empty?
      source_url = "https://bower.herokuapp.com/packages"
      p "Going to use default url: `#{source_url}`"
    end

    if concurrent
      crawl_concurrent(token, source_url)
    else
      crawl_serial(token, source_url)
    end
  end

  #for debugging
  def self.crawl_serial(token, source_url)
    p "Using serial crawler - hopefully just for debugging."
    crawl_registered_list(source_url)
    crawl_existing_sources(token)
    crawl_projects(token)
    crawl_versions(token) 
  end

  def self.crawl_concurrent(token, source_url)
    p  "running Bower crawler on concurrent threads."
    
    tasks = []
    tasks << Thread.new {crawl_registered_list(source_url)}
    tasks << Thread.new {crawl_existing_sources(token)}
    tasks << Thread.new {crawl_projects(token)}
    tasks << Thread.new {crawl_versions(token)}

    tasks.each {|task| task.join}
    p "All task of Bower crawler are finished now. Have a good day!"
  end

  def self.crawl_registered_list(source_url)
    #fetches list of all registered bower packages
    content = HTTParty.get(source_url)
    app_list = JSON.parse(content, symbolize_names: true)
    tasks = 0

    if app_list.nil? or app_list.empty?
      p "Error: cant read list of registered bower packages from: `#{source_url}`"
      return nil
    end
    
    app_list.each_with_index do |app, i|
      repo_info = url_to_repo_info(app[:url])
      if repo_info.nil? or repo_info.empty?
        #save non-supported url for further analyse
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
    p "#-- Got #{tasks} registered libraries of Bower."
  end
  
  #checks does url of source exists or not
  def self.crawl_existing_sources(token)
    task_name = A_TASK_CHECK_EXISTENCE
    next_task_name = A_TASK_READ_PROJECT

    crawler_task_executor(task_name, next_task_name, token) do |task, token|
      result = check_repo_existence(task, token)
    end
  end

  #imports information of existing project file 
  def self.crawl_projects(token)
    task_name = A_TASK_READ_PROJECT
    next_task_name = A_TASK_READ_VERSIONS
    crawler_task_executor(task_name, next_task_name, token) do |task, token|      
      result = add_bower_package(task, token)
      if result == true
        task.update_attributes({crawled_at: DateTime.now})
        to_version_task(task) #add new version task when everything went oK
      end
      sleep 1/100 #force little pause before next iteration
      result
    end
  end

  #imports package versions
  def self.crawl_versions(token)
    task_name = A_TASK_READ_VERSIONS
    next_task_name = nil

    crawler_task_executor(task_name, next_task_name, token) do |task, token|
      tags = Github.repo_tags(task[:repo_fullname], token) 
      if tags.nil?
        p "`#{task[:repo_fullname]}` has no versions - going to skip."
        result = false
      else
        p "#{task[:repo_fullname]} has #{tags.to_a.count} tags."
        prod = Product.fetch_product(Product::A_LANGUAGE_JAVASCRIPT, task[:repo_fullname])
        if prod.nil?
          p "Cant find product for #(Product::A_LANGUAGE_JAVASCRIPT)/#{task[:repo_full]}"
          next
        end
        
        tags.each do |tag| 
          parse_repo_tag(prod, tag, token)
          sleep 1/100 #just force little pause asking commit info -> github may block
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

  #using: task_executor(task_name, next_task_name) {|task_name, next_task_name| crawl_money}
  def self.crawler_task_executor(task_name, next_task_name, token, &block)
    p "#-- #{task_name} is starting ... "
    start_time = Time.now
    success = 0; failed = 0
    while true do
      check_request_limit(token)
      task = get_task_for(task_name)
      next if task.nil?

      if task[:poison_pill] == true
        task.delete
        p "#-- #{task_name} got poison pill. Going to die ..."
        break
      end

      #worker content
      if block_given?
        result = yield(task, token)
      else
        p "Task executor got no execution block."
        break
      end
      #return boolean in your block when want to update these metrics
      if result
        success += 1
        waited = 0 
        task.update_attributes({
          crawled_at: DateTime.now,
          re_crawl: false
        })
      else
        failed += 1
        task.update_attributes({
          task_failed: true,
          fails: task[:fails] + 1,
          re_crawl: false
        })
      end

      p "#{task_name}| success: #{success} , failed: #{failed}"
    end
    
    to_poison_pill(next_task_name) if next_task_name
    unfinished = CrawlerTask.by_task(task_name).crawlable.count
    runtime = Time.now - start_time
    p "#-- #{task_name} is done in #{runtime} seconds. success: #{success}, failed: #{failed}, unfinished: #{unfinished}"
  rescue Exception => ex
    puts ex.message
    puts ex.backtrace.join("\n")
    to_poison_pill(next_task_name) if next_task_name
  end

  def self.get_task_for(task_name)
    task = nil
    100.times do |i|
      task = CrawlerTask.by_task(task_name).crawlable.desc(:weight).shift
      break unless task.nil?
      
      p "No tasks for #{task_name} - going to wait #{A_SLEEP_TIME} seconds before re-trying again"
      sleep A_SLEEP_TIME
    end

    to_poison_pill(task_name) if task.nil? 
    task
  end

  def self.check_repo_existence(task, token)
    success =  false
    read_task = to_read_task(task, task[:url])
    response = Github.repo_info(task[:repo_fullname], token, true, read_task[:crawled_at])

    if response.class != HTTParty::Response
      success = true
      p "Something went wrong with asking info about #{task[:repo_fullname]}- did not get any response."
    elsif response.code > 199 and response.code < 300
      repo = JSON.parse response.body
      read_task.update_attributes({
        weight: repo['stargazers_count'] + repo['watchers_count'] + 10,
        task_failed: false,
        url_exists: true,
        re_crawl: true
      })
      task.update_attributes({re_crawl: false, url_exists: true, crawled_at: DateTime.now})
      success = true
    elsif response.code == 304
      p "No changes for `#{task[:repo_fullname]}` since last crawling `#{read_task[:crawled_at]}`. Going to skip."
      task.update_attributes({
        url_exists: true,
        re_crawl: false
      })
      success = true
    elsif response.code == 404
      p "Error: #{task[:repo_fullname]} with url `#{task[:url]}` doesnt exists."
      task.update_attributes({
        fails: task[:fails] + 1,
        url_exists: false,
        task_failed: true,
        recrawl: false
      })
    elsif response.code >= 500
      #when service down
      p "Error: Sadly Github is down; cant access #{task[:url]}"
      task.update_attributes({
        fails: task[:fails] + 1,
        re_crawl: true,
        task_failed: true,
      })
    end

    return success
  end
 
  def self.add_bower_package(task, token)
    p "#-- reading #{task[:repo_fullname]} from url: #{task[:url]}"

    pkg_info = self.read_project_info_from_github(task, token)
    result = false
    prod = nil
    prod = create_bower_package(pkg_info, token) if pkg_info

    if prod and prod.save
      task.update_attributes({
        re_crawl: false,
        runs: task[:runs] + 1,
        task_failed: true
      })
      result =  true
    else
      task.update_attributes({
        re_crawl: false,
        runs: task[:runs] + 1,
        fails: task[:fails] + 1,
        task_failed: true
      })
    end
    result
  end
  #saves product and save sub/related docs
  def self.create_bower_package(pkg_info, token)
    prod = to_product(pkg_info)
    prod[:version] = pkg_info[:version]

    versionlink = to_version_link(prod, prod[:version], pkg_info[:url])
    prod.versions << to_version(pkg_info)
    
    pkg_info[:licenses].to_a.each {|lic| to_license(prod, lic)}
    deps = to_dependencies(prod, pkg_info)
    deps.to_a.each {|dep| prod.dependencies << dep}
    deps = to_dev_dependencies(prod, pkg_info)
    deps.to_a.each {|dep| prod.dependencies << dep}

    prod
  end

  def self.read_project_info_from_github(task, token)
    pkg_info = nil
    supported_files = Set.new ['bower.json', 'component.json', 'module.json', 'package.json']
    
    owner = task[:repo_owner]
    repo = task[:repo_name]
    full_name = task[:repo_fullname]
    repo_url = task[:url]
    #return nil unless Github.repo_changed?(full_name, task[:updated_at], token)
    supported_files.to_a.each do |filename|
      file_url = "#{Github::A_API_URL}/repos/#{task[:repo_fullname]}/contents/#{filename}"
      project_file = read_project_file_from_url(file_url, token)
      if project_file.is_a?(Hash)
        p "Found: #{filename} for #{task[:repo_fullname]}"
        pkg_info = to_pkg_info(owner, repo, repo_url, project_file) 
        break
      end
    end
    
    if pkg_info.nil?
      p "#{task[:repo_fullname]} has no supported project files. #{supported_files.to_a}"
    end

    pkg_info
  end

  def self.read_project_file_from_url(file_url, token)
    content = Github.fetch_raw_file(file_url, token)
    return nil if content.nil?  
    content = JSON.parse(content, symbolize_names: true)
    content
  rescue => e
    p "Error: cant parse JSON file for #{file_url}.", e.message
    nil
  end

  def self.parse_repo_tag(prod, tag, token)
    if prod.nil? or tag.nil?
      p "Product or tag cant be nil"
      return
    end
    tag = tag.deep_symbolize_keys
    bower_parser = BowerParser.new
    tag_name = tag[:name].to_s
    tag_name = bower_parser.cleanup_version(tag_name)
    m = tag_name.match bower_parser.rules[:full_version]

    if m.nil? or !m[:version]
      p "Skipped tag `#{tag[:name].to_s}` "
      return
    end
    
    check_request_limit(token)
    commit_info = Github.get_json(tag[:commit][:url], token)
    unless commit_info.nil?
      released_at = commit_info[:commit][:committer][:date].to_s.to_datetime
    else
      p "No commit info for tag `#{tag_name}` url: #{tag[:commit][:url]}"
      released_at = nil
    end

    if prod.version_by_number(tag_name).nil?
      #add version only if there's no version with same label

      new_version = Version.new version:        tag_name,
                                prerelease:     !m[:prerelease].nil?,
                                prerelease_tag: m[:prerelease],
                                build:          !m[:build].nil?,
                                build_tag:      m[:build],
                                released_at:    released_at
      prod.versions << new_version
      newest = to_newest(prod, new_version)

      p "Added version `#{new_version[:version]}` with release_date `#{new_version[:released_at]}`"
    end
   
    if tag.has_key?(:zipball_url)
      to_version_archive(prod, tag_name, tag[:zipball_url])
    end

    url = "https://www.github.com/#{prod[:prod_key]}"
    to_version_link(prod, tag_name, url, "Github")
  end

  def self.check_request_limit(token)
    if rate_limits.nil?
      val = github_rate_limit(token)
      rate_limits(val)
    end

    if rate_limits.nil?  or not rate_limits.has_key?(:core)
      p "Failed to check rate limits."
      sleep A_SLEEP_TIME
      return
    end

    @@rate_limits[:core][:remaining] -= 1
    limits = rate_limits[:core]
    time_left = (limits[:reset] - Time.now.to_i) / 60 #in minutes
    time_left += 1 #add additional minute for rounding errors and warming up
    if limits[:remaining] <= A_MINIMUM_RATE_LIMIT and time_left > 0
      p "Remaining rate limits. #{limits}"
      p "Going to stop crawling for next #{time_left} minutes"
      rate_limits(nil)
      sleep time_left.minutes
      p "Waking up and going to continue crawling." 
    end
    
    if (limits[:remaining] % 100) == 0 or limits[:remaining] < (A_MINIMUM_RATE_LIMIT + 10)
      val = github_rate_limit(token)
      rate_limits(val)
      p "#-- Remaining request limits: #{limits}"
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
      weight: -10  #will be the last when getting sorted list
    })

    task
  end

  def self.to_newest(prod, version)
    newest = Newest.find_or_create_by(
      prod_key: prod[:prod_key], 
      language: prod[:language], 
      version: version[:version]
    )

    newest.update_attributes({
      name: prod[:name],
      version: version[:version],
      prod_type: Project::A_TYPE_BOWER,
      created_at: version[:released_at] || newest[:created_at]
    })
    newest
  rescue => e
    p "Cant save newest: #{newest.to_json}.\n #{e.message} \n #{e.backtrace.join('\n')}"
  end


  def self.to_product(pkg_info)
    prod = Product.find_or_create_by(
       prod_key: pkg_info[:full_name].to_s.downcase,
       language: Product::A_LANGUAGE_JAVASCRIPT, 
    )

    prod.update_attributes({
      name: pkg_info[:name].to_s,
      name_downcase: pkg_info[:name].to_s.downcase,
      prod_type: Project::A_TYPE_BOWER,
      private_repo: pkg_info[:private_repo],
      description: pkg_info[:description].to_s 
    })
    prod
  end

  def self.to_version_link(prod, version, url, link_name = "scm")
    new_link = Versionlink.find_or_create_by(
      language: prod[:language],
      prod_key: prod[:prod_key],
      version: version,
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
      version: version,
      name: name
    )
    new_link.update_attributes({
      link: url,
      name: name
    })

    new_link
  end


  def self.to_version(pkg_info)
    Version.new version: pkg_info[:version],
                link: pkg_info[:url],
                released_at: DateTime.now() #not actual release date for version in project file
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
    return nil if !pkg_info.has_key?(:dependencies) or pkg_info[:dependencies].nil? or pkg_info[:dependencies].empty?

    deps = []
    if not pkg_info[:dependencies].is_a?(Hash)
      p "#{prod[:prod_key]} dependencies have wrong structure. `#{pkg_info[:dependencies]}`"
      return nil
    end

    pkg_info[:dependencies].each_pair do |prod_name, version|
      next if prod_name.to_s.empty?
      dep = to_dependency(prod, prod_name, version)
      deps << dep if dep
    end
    deps
  end

  def self.to_dev_dependencies(prod, pkg_info)
    return nil if !pkg_info.has_key?(:dev_dependencies) or pkg_info[:dev_dependencies].nil? or pkg_info[:dev_dependencies].empty?

    deps = [] 
    if not pkg_info[:dev_dependencies].is_a?(Hash)
      p "DevDependecies for #{prod[:prod_key]} have wrong structure. `#{pkg_info[:dev_dependencies]}`"
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
    
    dep =  Dependency.find_or_create_by( 
      language: prod[:language],
      dep_prod_key: dep_name,
      prod_key: prod[:prod_key].to_s.downcase,
      prod_version: prod[:version],
    )

    dep.update_attributes({
      name: dep_name,
      prod_type: Project::A_TYPE_BOWER,
      dep_version: dep_version, #TODO: git tag / path
      version: dep_version,
      scope: scope
    })
    dep
  rescue => e
    p "Error: Cant save dependency `#{dep_name}` with version `#{dep_version}` for #{prod[:prod_key]}."
    p e.message
  end

  def self.to_pkg_info(owner, repo, project_url, project_info)
    info = {
      name: repo,
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
    git_url_matcher = /^git:\/\/github.com/i
    git_io_matcher = /github.io/i
    urlpath = repo_url.gsub(/:\/+|\/+|\:/, "_")
  
    if repo_url =~ git_url_matcher
      _, _, owner, repo = urlpath.split(/_/)
    elsif repo_url =~ git_io_matcher
      _, owner, repo, _ = urlpath.split('_')
      owner = owner.split('.').first
    else
      #TODO: add support for private hosts
      p "#------------------------------------------------------------",
        "warning: going to ignore #{repo_url} - its not github repo, cant read bower.json"
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
