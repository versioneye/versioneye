#TODO: check ratelimit
#TODO: no removing prev doc => update values + add new version

class BowerCrawler

  A_MINIMUM_RATE_LIMIT = 10

  def self.clean
    Product.where(prod_type: Project::A_TYPE_BOWER).delete_all
    Newest.where(prod_type: Project::A_TYPE_BOWER).delete_all
 end

  def self.crawl(source_url = nil)
    #TODO: special user for BowerCrawler 
    admin = User.find_by_email "admin@versioneye.com"
    @@token = admin[:github_token]

    if source_url.to_s.strip.empty?
      source_url = "https://bower.herokuapp.com/packages"
      p "Going to use default url: `#{source_url}`"
    end

    #fetches list of all registered bower packages
    content = HTTParty.get(source_url)
    unless content
      p "Error: cant read list of registered bower packages from: `#{source_url}`"
    end
    
    app_list = JSON.parse(content, symbolize_names: true)
    if app_list.nil? or app_list.empty?
      p "Error: got empty list of registered bower packages ;"
      return nil
    end

    add_bower_packages(app_list, @@token)
  end

  def self.add_bower_packages(app_list, token)
    imported = 0
    failed = 0

    app_list.to_a.each_with_index do |app, i|
      check_rate_limit if (i % A_MINIMUM_RATE_LIMIT) == 0
      
      p "#-- iteration #{i}, reading : #{app[:url]}"
      pkg_info = self.read_info_from_github(app[:url], token)

      if pkg_info
        prod = add_bower_package(pkg_info, token)
      else
        p "Skipped: `#{app[:url]}`."
        next
      end

      #TODO: if product didnt get version from project file and has versions; use latest

      if prod and prod.upsert
        #add also new newest entity
        newest = Newest.new name: prod[:name],
                            version: prod[:version],
                            language: prod[:language],
                            prod_key: prod[:prod_key],
                            prod_type: prod[:prod_type]
        begin
          newest.upsert
        rescue => e
          p "Cant save newest: #{newest.to_json}.\n #{e.message} #{newest.errors.full_messages.to_sentence}"
        end
        imported += 1
        p "Imported: #{prod[:prod_key]}"
      else
        p "#-- Failed to save: '#{app}'"
        failed += 1
      end
   end

    p "#-- Done! imported: #{imported} , failed: #{failed}"
  end

  def self.add_bower_package(pkg_info, token)
      prod = to_product(pkg_info)
      versionlink = to_versionlink(prod, pkg_info)

      prod[:version] = pkg_info[:version]
      prod.versions << to_version(pkg_info)
      
      prod_license = to_license(prod, pkg_info)
      deps = to_dependencies(prod, pkg_info)
      deps.to_a.each {|dep| prod.dependencies << dep}

      #-- try to read versioninfo & versionarchive to tags
      tags = Github.repo_tags(pkg_info[:full_name], token)
      if tags and not tags.empty?
        p "Repo `#{pkg_info[:full_name]}` has #{tags.to_a.count} tags."
        self.parse_repo_tags(prod, tags)
      end
      prod
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

  def self.to_product(pkg_info)
    Product.new  name: "#{pkg_info[:full_name]}",
                 name_downcase: pkg_info[:full_name].to_s.downcase,
                 prod_key: pkg_info[:full_name].to_s,
                 prod_type: Project::A_TYPE_BOWER,
                 language: Product::A_LANGUAGE_JAVASCRIPT,
                 private_repo: pkg_info[:private_repo],
                 description: pkg_info[:description].to_s 
  end

  def self.to_versionlink(prod, pkg_info, link_name = "scm")
    new_version = Versionlink.new language: prod[:language],
                                  prod_key: prod[:prod_key],
                                  link: pkg_info[:url],
                                  name: link_name
    new_version.save
    new_version
  end

  def self.to_version(pkg_info)
    Version.new version: pkg_info[:version],
                link: pkg_info[:url]
  end

  def self.to_license(product, pkg_info)
    return nil if product.nil?

    new_licence = License.new name: pkg_info[:license] || "unknown",
                              field: product[:language],
                              prod_key: product[:prod_key],
                              version: pkg_info[:version]
    new_licence.save
    new_licence
  end

  def self.to_dependencies(prod, pkg_info)
    deps = []
   
    pkg_info[:dependencies].each_pair do |prod_name, version|
      next if prod_name.to_s.empty? #ignore dependencies with no-names

      dep_key = "#{prod[:pkg_manager]}/#{prod_name}"
      dep =  Dependency.new name: prod_name,
                            prod_type: Project::A_TYPE_BOWER,
                            language: prod[:language],
                            version: version,
                            prod_key: prod[:prod_key],
                            prod_version: prod[:version],
                            dep_prod_key: dep_key,
                            scope: Dependency::A_SCOPE_REQUIRE

      dep.save
      deps << dep
    end

    deps
  end

  def self.read_info_from_github(source_url, token, filename = "bower.json")
    info = {
      version: nil,
      license: "unknown",
      dependencies: {},
      url: source_url,
      private_repo: false,
      group_id: nil, #github user name
      artifact_id: nil, #github repo name
    }

    unless source_url =~ /^git:\/\/github\.com/i
      #TODO: add support for private hosts
      p "#------------------------------------------------------------",
        "warning: going to ignore #{source_url} - its not github repo, cant read bower.json"
      info[:private_repo] = true
      return nil
    end
    urlpath = source_url.gsub(/:\/+|\/+|\:/, "_")
    _, _, owner, repo = urlpath.split(/_/)

    repo.to_s.gsub!(/\.git$/, "")
    info[:name] = repo
    info[:group_id] = owner
    info[:artifact_id] = repo
    info[:full_name] = "#{owner}/#{repo}"
    url = "#{Github::A_API_URL}/repos/#{owner}/#{repo}/contents/#{filename}"
   
    return nil unless repo_changed?(info[:full_name])

    content = Github.fetch_raw_file(url, token)
    if content
      begin
      p "Found: #{filename}"
      info.merge! JSON.parse(content, symbolize_names: true)
      rescue
        p "Error: cant parse JSON file for #{url}."
      end
    else
      #try to read package.json
      if filename != "package.json"
        info = self.read_info_from_github(source_url, token, "package.json")
      else
        p "No project file."
      end
    end

    info
  end

  def self.repo_changed?(repo_name)
 
    repo_changed = true
    existing_package = Product.fetch_product(Product::A_LANGUAGE_JAVASCRIPT, repo_name)

    return repo_changed if existing_package.nil?
    
    repo_changed = Github.repo_changed?(repo_name, existing_package[:updated_at], @@token)

    unless repo_changed
      p "No changes for Bower package `#{repo_name}`. Going to skip it."
      repo_changed =  false
    else 
      p "Detect changes for existing package `#{repo_name}`. Going to re-import everything"
      existing_package.destroy
    end

    repo_changed
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

      new_version = Version.new version: m[:version],
                                prerelease: !m[:prerelease].nil?,
                                released_at: released_at
      prod.versions << new_version
      p "Added version `#{new_version[:version]}` with release_date `#{new_version[:released_at]}`"
      
      new_link = Versionarchive.new language: prod[:language],
                                    prod_key: prod[:prod_key],
                                    version_id: m[:version],
                                    link: tag['zipball_url'],
                                    name: "#{prod[:prod_key]}_#{m[:version]}.zip"
      new_link.save
    else
      p "Skipped tag `#{tag_name}` "
    end
  end
end
