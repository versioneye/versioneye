class ProductFactory

  def self.create_new(n = 1, manager_type = :maven, save_db = true, version = nil)
    name = "test_#{manager_type.to_s}_#{n}"
    if version.nil?
      version = "#{Random.rand(0..4)}.#{Random.rand(1..9)}"
    end

    case manager_type.to_sym
    when :maven
      product = self.create_for_maven("versioneye", name, version)
    when :composer
      product = self.create_for_composer(name, version)
    when :gemfile
      product = self.create_for_gemfile(name, version)
    when :podfile
      product = self.create_for_cocoapods(name, version)
    end

    if save_db and not product.save
      puts product.errors.full_messages.to_sentence
    end
    return product
  end


  def self.create_for_maven(group_id, artifact_id, version)
    version_obj = Version.new :version => version
    product = Product.new(
      {
        :name          => artifact_id,
        :name_downcase => artifact_id.downcase,
        :group_id      => group_id,
        :artifact_id   => artifact_id,
        :prod_key      => "#{group_id}/#{artifact_id}",
        :language      => Product::A_LANGUAGE_JAVA,
        :prod_type     => Project::A_TYPE_MAVEN2,
        :version       => version
      })
    product.versions.push(version_obj)
    product
  end

  def self.create_for_cocoapods(name, version)
    version_obj = Version.new :version => version
    product = Product.new(
      {
        :name          => name,
        :name_downcase => name.downcase,
        :prod_key      => name.downcase,
        :language      => Product::A_LANGUAGE_OBJECTIVEC,
        :prod_type     => Project::A_TYPE_COCOAPODS,
        :version       => version
      })
    product.versions.push(version_obj)
    product
  end

  def self.create_for_bower(name, version)
    version_obj = Version.new :version => version
    product = Product.new(
      {
        :name          => name,
        :name_downcase => name.downcase,
        :prod_key      => name.downcase,
        :language      => Product::A_LANGUAGE_JAVASCRIPT,
        :prod_type     => Project::A_TYPE_BOWER,
        :version       => version
      })
    product.versions.push(version_obj)
    product
  end


  def self.create_for_composer(name, version)
    product = Product.new
    product.name = name
    product.name_downcase = name.downcase
    product.prod_key = name
    product.language = Product::A_LANGUAGE_PHP
    version_obj = Version.new
    version_obj.version = version
    product.versions.push(version_obj)
    product.version = version
    product.prod_type = Project::A_TYPE_COMPOSER
    product
  end


  def self.create_for_gemfile(name, version)
    product = Product.new({:name => name, :name_downcase => name.downcase, :prod_key => name})
    product.language = Product::A_LANGUAGE_RUBY
    product.prod_type = Project::A_TYPE_RUBYGEMS
    product.versions.push( Version.new(:version => version) )
    product.version = version
    product
  end


  def self.create_for_pip(name, version)
    product = Product.new name: name,
                          name_downcase: name.downcase,
                          prod_key: name,
                          language: Product::A_LANGUAGE_PYTHON,
                          prod_type: Project::A_TYPE_PIP,
                          version: version

    version_obj = Version.new version: version
    product.versions.push(version_obj)

    product
  end


end
