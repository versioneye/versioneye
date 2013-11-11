#TODO: check ratelimit
#TODO: no removing prev doc => update values + add new version

class BowerCrawler
  def self.clean
    Product.where(prod_type: Project::A_TYPE_BOWER).delete_all
  end

  def self.crawl(source_url = nil)
    if source_url.to_s.strip.empty?
      source_url = "https://bower.herokuapp.com/packages"
      p "Going to use default url: `#{source_url}`"
    end

    #fetches list of all registered bower packages
    content = HTTParty.get(source_url)
    unless content
      p "Error: cant read list of registered bower packages from: `#{source_url}`"
    end
   
    admin = User.find_by_email "admin@versioneye.com"

    app_list = JSON.parse(content, symbolize_names: true)
    add_bower_packages(app_list, admin[:github_token])
  end

  #for saved list of packages
  def self.import_from_file(filepath)
    unless File.file?(filepath)
      p "Error: uncorrect path : `#{filepath}`"
      return
    end

    json_file = File.new(filepath, 'r')
    app_list = JSON.parse(json_file.read, symbolize_names: true)
    add_bower_packages(app_list)
  end

  def self.add_bower_packages(app_list, token)
    imported = 0
    failed = 0

    app_list.to_a.each do |app|
      #read project's bower on github to get more info
      pkg_info = self.read_info_from_github(app[:url], token)

      unless pkg_info
        p "Cant read info from: `#{app[:url]}`. Going to try luck with next package."
        next
      end

      prod = to_product(pkg_info)
      versionlink = to_versionlink(prod, pkg_info)

      prod[:version] = pkg_info[:version]
      prod.versions << to_version(pkg_info)
      
      prod_license = to_licence(pkg_info)
      deps = to_dependencies(prod, pkg_info)
      deps.to_a.each {|dep| prod.dependencies << dep}

      #-- try to read versioninfo & versionarchive to tags
      tags = Github.repo_tags(pkg_info[:full_name], token)
      if tags and not tags.empty?
        p "Repo `#{pkg_info[:full_name]}` has #{tags.to_a.count} tags."
        parse_repo_tags(tags)
      end

      if prod.upsert
        p "Imported: #{prod[:name]}"
        imported += 1
      else
        p "#------------------------", "Failed to save: '#{app}'"
        failed += 1
      end
    end

    p "#-- Done! imported: #{imported} , failed: #{failed}"
  end

  def self.to_product(pkg_info)
    Product.new  name: pkg_info[:name],
                 name_downcase: pkg_info[:name].to_s.downcase,
                 prod_key: "bower/#{pkg_info[:name]}",
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
      version: "*",
      license: "unknown",
      dependencies: {},
      url: source_url,
      private_repo: false,
      group_id: nil, #github user name
      artifact_id: nil, #github repo name
    }

    unless source_url =~ /^git:\/\/github\.com/i
      p "warning: going to ignore #{source_url} - its not github repo, cant read bower.json"
      info[:private_repo] = true
      return info
    end
    urlpath = source_url.gsub(/:\/+|\/+|\:/, "_")
    _, _, owner, repo = urlpath.split(/_/)

    p "#-- #{source_url}, #{owner}, #{repo}"
    repo.to_s.gsub!(/\.git$/, "")
    info[:name] = repo
    info[:group_id] = owner
    info[:artifact_id] = repo

    url = "#{Github::A_API_URL}/repos/#{owner}/#{repo}/contents/#{filename}"
    content = Github.fetch_raw_file(url, admin[:github_token])
    if content
      begin
      info.merge! JSON.parse(content)
      p "This project had #{filename}"
      rescue
        p "Error: cant parse JSON file for #{url}."
      end
    else
      #try to read package.json
      if filename != "package.json"
        info = self.read_info_from_github(source_url, "package.json")
      else
        p "No project file."
      end
    end

    info
  end

  def parse_repo_tags(prod, tags)
    tags.each {|tag| save_repo_tag(prod, tag)}
  end

  def save_repo_tag(prod, tag)
    #TODO: add version & date - use tag[:url]
    #TODO: save downloadable zip-barballs; tag[:zipball_url]
  end
end
