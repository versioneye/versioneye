class ComposerLockParser < ComposerParser

  def parse( url )
    dependencies = self.fetch_project_dependencies(url)
    project = init_project( url )
    dependencies.each do |package|
      self.process_package project, package
    end
    project.dep_number = project.dependencies.size
    project
  end

  def process_package project, package
    dependency = Projectdependency.new
    dependency.name = package['name']
    dependency.language = Product::A_LANGUAGE_PHP

    product = Product.fetch_product Product::A_LANGUAGE_PHP, dependency.name
    dependency.prod_key = product.prod_key if product

    version = self.fetch_package_version( package )
    self.parse_requested_version(version, dependency, product)

    project.out_number     += 1 if dependency.outdated?
    project.unknown_number += 1 unless product

    project.projectdependencies.push dependency
  end

  def fetch_package_version(package)
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

    version.gsub! /^v/i, ''
    version
  end

  def fetch_project_dependencies( url )
    return nil if url.nil?
    response = self.fetch_response( url )
    data = JSON.parse(response.body)
    return nil if data.nil?  or data['packages'].nil?
    data['packages']
  end

end
