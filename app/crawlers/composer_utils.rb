class ComposerUtils


  def self.create_license( product, version_number, version_obj )
    license = version_obj['license']
    return nil if license.nil? || license.empty?
    license.each do |license_name|
      license_obj = License.new({ :language => product.language, :prod_key => product.prod_key,
        :version => version_number, :name => license_name })
      license_obj.save
    end
  end


  def self.create_developers authors, product, version_number
    return nil if authors.nil? || authors.empty?

    authors.each do |author|
      author_name     = author['name']
      author_email    = author['email']
      author_homepage = author['homepage']
      author_role     = author['role']
      devs = Developer.find_by Product::A_LANGUAGE_PHP, product.prod_key, version_number, author_name
      next if devs && !devs.empty?

      developer = Developer.new({:language => Product::A_LANGUAGE_PHP,
        :prod_key => product.prod_key, :version => version_number,
        :name => author_name, :email => author_email,
        :homepage => author_homepage, :role => author_role})
      developer.save
    end
  end


  def self.create_archive product, version_number, version_obj
    dist = version_obj['dist']
    return nil if dist.nil? || dist.empty?
    dist_url  = dist['url']
    dist_type = dist['type']
    dist_name = "#{product.name}.#{dist_type}"
    archive = Versionarchive.new({:language => Product::A_LANGUAGE_PHP, :prod_key => product.prod_key,
      :version_id => version_number, :name => dist_name, :link => dist_url})
    Versionarchive.create_if_not_exist_by_name( archive )
  end


  def self.create_dependencies product, version_number, version_obj
    require_dep = version_obj['require']
    create_dependency require_dep, product, version_number, 'require'

    require_dev = version_obj['require-dev']
    create_dependency require_dev, product, version_number, 'require-dev'

    replace = version_obj['replace']
    create_dependency replace, product, version_number, 'replace'

    suggest = version_obj['suggest']
    create_dependency suggest, product, version_number, 'suggest'
  end


  def self.create_dependency dependencies, product, version_number, scope
    return nil if dependencies.nil? || dependencies.empty?
    dependencies.each do |dep|
      require_name    = dep[0]
      require_version = dep[1]
      if require_version.strip.eql?("self.version")
        require_version = version_number
      end
      dep_prod_key = require_name
      dep = Dependency.find_by( Product::A_LANGUAGE_PHP, product.prod_key, version_number, require_name, require_version, dep_prod_key )
      next if dep

      dependency = Dependency.new({:name => require_name, :version => require_version,
        :dep_prod_key => dep_prod_key, :prod_key => product.prod_key,
        :prod_version => version_number, :scope => scope, :prod_type => Project::A_TYPE_COMPOSER,
        :language => Product::A_LANGUAGE_PHP })
      dependency.save
      dependency.update_known
    end
  end


end
