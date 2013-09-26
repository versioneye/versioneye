class Bower
  def self.clean
    Product.where(prod_type: Project::A_TYPE_BOWER).delete_all
  end

  def self.import_from_url(source_url = nil)
    if source_url.to_s.strip.empty?
      source_url = "https://bower.herokuapp.com/packages"
      p "Going to use default url: `#{source_url}`"
    end

    content = HTTParty.get(source_url)
    unless content
      p "Error: cant read bower packages from: `#{source_url}`"
    end

    app_list = JSON.parse(content, symbolize_names: true)
    add_bower_packages(app_list)
  end

  def self.import_from_file(filepath)
    unless File.file?(filepath)
      p "Error: uncorrect path : `#{filepath}`"
      return
    end

    json_file = File.new(filepath, 'r')
    app_list = JSON.parse(json_file.read, symbolize_names: true)
    add_bower_packages(app_list)
  end

  def self.add_bower_packages(app_list)
    imported = 0
    failed = 0

    app_list.to_a.each do |app| 
      #read project's bower on github to get more info
      pkg_info = self.read_info_from_github(app[:url])
    
      unless pkg_info
        p "Cant read info from: `#{app[:url]}`. Going to try luck with next package."
        next
      end

      prod = to_product(pkg_info)
      versionlink = to_versionlink(prod, pkg_info)
      versionlink.save

      prod[:version] = pkg_info[:version]
      prod.versions << to_version(pkg_info)
      deps = to_dependencies(prod, pkg_info)
      deps.to_a.each {|dep| prod.dependencies << dep}

      if prod.save
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

  def self.to_versionlink(prod, pkg_info)
    Versionlink.new language: prod[:language],
                    prod_key: prod[:prod_key],
                    link: pkg_info[:url]
  end

  def self.to_version(pkg_info)
    Version.new version: pkg_info[:version],
                license: pkg_info[:license],
                description: pkg_info[:description],
                link: pkg_info[:url]
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

  def self.read_info_from_github(source_url, filename = "bower.json")
    info = {version: "*", license: "unknown", dependencies: {}, url: source_url, private_repo: false}
    
    unless source_url =~ /^git:\/\/github\.com/i
      p "warning: going to ignore #{source_url} - its not github repo, cant read bower.json"
      info[:private_repo] = true
      return info
    end
    urlpath = source_url.gsub(/:\/+|\/+|\:/, "_")
    _, _, owner, repo = urlpath.split(/_/)
    
    p "#-- #{source_url}, #{owner}, #{repo}"
    repo.gsub!(/\.git$/, "")
    info[:name] = repo

    url = "#{Github::A_API_URL}/repos/#{owner}/#{repo}/contents/#{filename}"
    admin = User.find_by_email "timgluz@gmail.com"
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

end
