#TODO: check ratelimit
#TODO: no removing prev doc => update values + add new version

class BowerCrawler

  A_MINIMUM_RATE_LIMIT = 10
  A_MAX_WAIT = 12 #12x10 ~> if dont get task in 120sec then stop worker
  A_SLEEP_TIME = 10
  A_TASK_CHECK_EXISTENCE = "bower_crawler/check_existence"
  A_TASK_READ_PROJECT = "bower_crawler/read_project"
  A_TASK_READ_TAGS    = "bower_crawler/read_tags"

  def self.clean
    Product.where(prod_type: Project::A_TYPE_BOWER).delete_all
    Newest.where(prod_type: Project::A_TYPE_BOWER).delete_all
    CrawlerTask.by_task(A_TASK_READ_PROJECT).delete_all
 end

  def self.crawl(token, source_url = nil)
    @@token = token
    if source_url.to_s.strip.empty?
      source_url = "https://bower.herokuapp.com/packages"
      p "Going to use default url: `#{source_url}`"
    end

    #TODO: add continuing from last place
    task1 = Thread.new {crawl_existing_sources(source_url, token)}
    task2 = Thread.new do
      begin
        crawl_bower_packages(token)
      rescue => e
        p "Exception on task.2", e.message
      end
    end
    task1.join; task2.join

    #for debugging 2nd worker
    #tasks = CrawlerTask.by_task(A_TASK_READ_PROJECT)
    #tasks.each_with_index {|task, i| add_bower_package(task, token, i)}
    #p "Crawler finished"
  end

  def self.crawl_existing_sources(source_url, token)
    #fetches list of all registered bower packages
    content = HTTParty.get(source_url)
    app_list = JSON.parse(content, symbolize_names: true)
   
    if app_list.nil? or app_list.empty?
      p "Error: cant read list of registered bower packages from: `#{source_url}`"
      return nil
    end
    
    p "Going to build list of active and changed Bowers packages."
    #TODO: add continue form last task
    app_list.each_with_index do |app, i|
      check_rate_limit if (i % A_MINIMUM_RATE_LIMIT) == 0
      repo_info = url_to_repo_info(app[:url])
      next if repo_info.nil? or repo_info.empty?
      check_repo_existence(repo_info, token)
    end

    total_tasks = CrawlerTask.by_task(A_TASK_READ_PROJECT)
    n_total = total_tasks.all.count
    n_failed = total_tasks.where(exists: false).count
    n_unfinished = total_tasks.where(task_done: false).count
    p "#-- #{A_TASK_CHECK_EXISTENCE} is done.",
      "#{n_total}.existing projects;",
      "#{n_failed}.dead projects",
      "#{n_unfinished} unfinished tasks"
  
    true
  end

  def self.check_repo_existence(repo_info, token)
    task = CrawlerTask.find_or_create_by( task_target: A_TASK_READ_PROJECT,
                                          task_source: A_TASK_CHECK_EXISTENCE,
                                          repo_name: repo_info[:repo],
                                          repo_owner: repo_info[:owner],
                                          source: CrawlerTask::A_SOURCE_GITHUB,
                                          url: repo_info[:url],
                                          repo_fullname: repo_info[:full_name])

    response = Github.repo_info(repo_info[:full_name], token, task[:updated_at], true)
    if response.class != HTTParty::Response
      p "Got exception for #{repo_info[:url]}"
      p "class? #{response.class}" 
    elsif response.code > 199 and response.code < 300
      repo = JSON.parse response.body
      task.update_attributes({
        repo_weight: repo['stargazers_count'] + repo['watchers_count'],
        url_exists: true,
        runs: task[:runs] + 1,
        re_crawl: true
      })
    elsif response.code == 404
      p "Repo #{repo_info[:full_name]} with url `#{repo_info[:url]}` doesnt exists."
      task.update_attributes({
        runs: task[:runs] + 1,
        fails: task[:fails] + 1,
        url_exists: false,
        task_failed: true,
      })
    elsif response.code >= 500
      #when service down
      p "Sadly Github is down; cant access  #{repo_info[:url]}"
      task.update_attributes({
        runs: task[:runs] + 1,
        fails: task[:fails] + 1,
        task_failed: true,
      })
    end

    task
  end
 
  def self.crawl_bower_packages(token)
    p "#-- Going to import project files"
    imported = 0
    failed = 0
    waited = 0 

    while waited <= A_MAX_WAIT do
      task = CrawlerTask.by_task(A_TASK_READ_PROJECT).re_crawlable.shift
      if task
        if add_bower_package(task, token, imported)
          imported += 1
          waited = 0 #after successful reading reset waited counter;
        else
          failed += 1
        end
        p "#{A_TASK_READ_PROJECT} imported: #{imported} | failed: #{failed}"
      else
        p "Still no re-crawlable tasks. Going to wait #{A_SLEEP_TIME}"
        sleep A_SLEEP_TIME
        waited += 1
      end
    end
    p "#-- Done! imported: #{imported} , failed: #{failed}"
  end
  
  def self.add_bower_package(task, token, imported)
    check_rate_limit if (imported % A_MINIMUM_RATE_LIMIT) == 0
    p "#-- reading #{task[:full_name]} from url: #{task[:url]}"
    pkg_info = self.read_project_info_from_github(task, token)
    result = false
    prod = nil
    prod = create_bower_package(pkg_info, token) if pkg_info

    if prod and prod.save
      newest = to_newest(prod) #newest model is used for latest_releases stats
      p "Imported: #{prod[:prod_key]}"
      task.update_attributes({
        re_crawl: false,
        runs: task[:runs] + 1,
        task_failed: true
      })
      result =  true
    else
      p "#-- Failed to import: '#{task[:repo_fullname]}'"
      task.update_attributes({
        re_crawl: true,
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

    #-- try to read versioninfo & versionarchive to tags
    tags = Github.repo_tags(pkg_info[:full_name], token)
    if tags and not tags.empty?
      p "Repo `#{pkg_info[:full_name]}` has #{tags.to_a.count} tags."
      self.parse_repo_tags(prod, tags)
    end

    #-- if prod didnt get versionnumber from project, then try to used latest from tags
    if prod[:version].nil?
      latest_version = prod.sorted_versions.first
      prod[:version] = latest_version[:version] if latest_version
    end

    prod
  end

  def self.read_project_info_from_github(task, token)
    pkg_info = nil
    supported_files = Set.new ['bower.json', 'component.json', 'package.json']
    
    owner = task[:repo_owner]
    repo = task[:repo_name]
    full_name = task[:repo_fullname]
    repo_url = task[:url]
    #TODO: refactor - needs to check is there any data in db to
    #return nil unless Github.repo_changed?(full_name, task[:updated_at], token)
    supported_files.to_a.each do |filename|
      file_url = "#{Github::A_API_URL}/repos/#{owner}/#{repo}/contents/#{filename}"
      project_file = read_project_file_from_url(file_url, token)
      if project_file.is_a?(Hash)
        p "Found: #{filename} for #{task[:repo_fullname]}"
        pkg_info = to_pkg_info(owner, repo, repo_url, project_file) 
        break
      end
    end
    
    if pkg_info.nil?
      p "Has no supported project files. #{supported_files.to_a}"
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

  def self.parse_repo_tags(prod, tags)
    return if tags.nil? or tags.empty?
    prod.versions.delete_all #we are going to reload anyway everything
    tags.each {|tag| parse_repo_tag(prod, tag)}
  end

  def self.parse_repo_tag(prod, tag)
    bower_parser = BowerParser.new
    tag_name = tag['name'].to_s
    tag_name = bower_parser.cleanup_version(tag_name)
    m = tag_name.match bower_parser.rules[:full_version]

    if m and m[:version]
      commit_info = Github.get_json(tag['commit']['url'], @@token)
      if commit_info
        released_at = commit_info['commit']['committer']['date'].to_s.to_datetime
      else
        released_at = nil
      end
 
      if prod.version_by_number(m[:version].to_s).nil?
        new_version = Version.new version: m[:version],
                                  prerelease: !m[:prerelease].nil?,
                                  released_at: released_at
        prod.versions << new_version
        p "Added version `#{new_version[:version]}` with release_date `#{new_version[:released_at]}`"
      end
      
      to_version_archive(prod, m[:version], tag['zipball_url'])
      url = "https://www.github.com/#{prod[:prod_key]}"
      to_version_link(prod, m[:version], url, "Github")
    else
      p "Skipped tag `#{tag_name}` "
    end
  end

  def self.check_rate_limit
    token = @@token
    rate_limits = Github.rate_limit @@token
    if rate_limits.nil?  or not rate_limits.has_key?('resources')
      p "Failed to check rate limits."
      return
    end

    limits = rate_limits['resources']['core']
    time_left = (limits['reset'] - Time.now.to_i) / 60 #in minutes
    if limits['remaining'] <= A_MINIMUM_RATE_LIMIT and time_left > 0
      p "Going to stop crawling for next #{time_left} minutes"
      sleep time_left.minutes
      p "Waking up and going to continue crawling."
    else
      p "Remaining rate limits: #{limits}"
    end
  end

  def self.to_newest(prod)
    newest = Newest.find_or_initialize_by(prod_key: prod[:prod_key], language: prod[:language], version: prod[:version])

    newest.update_attributes({ 
      version: prod[:version],
      prod_type: prod[:prod_type]
    })
    newest.save
    newest
  rescue => e
    p "Cant save newest: #{newest.to_json}.\n #{e.message} #{newest.errors.full_messages.to_sentence}"
  end


  def self.to_product(pkg_info)
    prod = Product.find_or_create_by(
       prod_key: pkg_info[:full_name].to_s.downcase,
       language: Product::A_LANGUAGE_JAVASCRIPT, 
    )

    prod.update_attributes({
      name: "#{pkg_info[:full_name]}",
      name_downcase: pkg_info[:full_name].to_s.downcase,
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
      name = "#{prod[:name]}_#{version}}.zip"
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
    if not pkg_info[:devDependencies].is_a?(Hash)
      p "DevDependecies for #{prod[:prod_key]} have wrong structure. `#{pkg_info[:devDependencies]}`"
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
      dependencies: project_info[:dependecies],
      dev_dependencies: project_info[:devDependencies],
      url: project_url,
      private_repo: false,
    }

    if project_info.has_key?(:license)
      license_info = project_info[:license]
      if license_info.is_a?(String)
        info[:licenses] = [{name: project_info[:license], url: nil}]
      elsif license_info.is_a?(Array)
        info[:licenses] = []
        license_info.each do |lic|
          info[:licenses] << {name: lic, url: nil}
        end
      end
    elsif project_info.has_key?(:licenses)
      #support for npm.js licenses
      info[:licenses] = []
      if project_info[:licenses].is_a?(Array)
        project_info[:licenses].to_a.each do |lic|
          info[:licenses] << {name: lic[:type], url: lic[:url]}
        end
      elsif project_info[:licenses].is_a?(Hash)
        lic = project_info[:licenses]
        info[:licenses] = [{name: lic[:type], url: lic[:url]}]
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
