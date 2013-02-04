class ComposerLockParser < CommonParser
  @@group_id = "php"

  def self.parse(url)
    dependencies = self.fetch_project_dependencies(url)
    project = Project.new
    project.dependencies = []

    dependencies.each do |package|
      dependency = Projectdependency.new
      dependency.name = package["name"]

      prod_key = "#{@@group_id}/#{dependency.name}"
      product = Product.find_by_key(prod_key)
      product = Product.find_by_key_case_insensitiv(prod_key) if product.nil?

      if product.nil?
        project.unknown_number += 1 
      else
        dependency.prod_key = product.prod_key
      end

      version = self.fetch_package_version(package)
      ComposerParser.parse_requested_version(version, dependency, product)
      dependency.update_outdated

      project.out_number += 1 if dependency.outdated?

      project.dependencies << dependency
    end

    project.project_type = "composer"
    project.dep_number = project.dependencies.count
    project
  end

  def self.fetch_package_version(package)
    return nil if package.nil? or package.empty? or not package.has_key?('version')
    version  = package['version']

    #if version string doesnt include any numbers, then look aliases
    unless version =~ /\d+/
      if package.has_key? 'extra' and package['extra'].has_key? 'branch-alias'
        aliases = package['extra']['branch-alias']
        alias_value = aliases[version] 
        version = alias_value unless alias_value.nil?
      end
    end

    #replace leading v
    version.gsub! /^v/i, ''
    version
  end

  def self.fetch_project_dependencies(url)
    return nil if url.nil?

    response = self.fetch_response(url)
    data = JSON.parse(response.body)
    return nil if data.nil?  or data['packages'].nil?

    data['packages']
  end

end
