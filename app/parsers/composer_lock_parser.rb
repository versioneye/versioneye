class ComposerLockParser < CommonParser
  @@group_id = "php"

  def parse( url )
    dependencies = self.fetch_project_dependencies(url)
    project = Project.new
    project.dependencies = []

    dependencies.each do |package|
      self.process_package project, package  
    end

    project.dep_number = project.dependencies.count
    project.project_type = Project::A_TYPE_COMPOSER
    project.language = Product::A_LANGUAGE_PHP
    project.url = url
    project
  end

  def process_package project, package 
    dependency = Projectdependency.new
    dependency.name = package["name"]

    product = self.product_by_key "#{@@group_id}/#{dependency.name}"
    dependency.prod_key = product.prod_key if product

    version = self.fetch_package_version(package)
    compposer_parser = ComposerParser.new 
    compposer_parser.parse_requested_version(version, dependency, product)
    
    dependency.update_outdated
    project.out_number += 1 if dependency.outdated?
    project.unknown_number += 1 unless product

    project.dependencies << dependency
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

    #replace leading v
    version.gsub! /^v/i, ''
    version
  end

  def fetch_project_dependencies(url)
    return nil if url.nil?

    response = self.fetch_response(url)
    data = JSON.parse(response.body)
    return nil if data.nil?  or data['packages'].nil?

    data['packages']
  end

  def product_by_key prod_key 
    product = Product.find_by_key(prod_key)
    product = Product.find_by_key_case_insensitiv(prod_key) if product.nil?
    product
  end

end
