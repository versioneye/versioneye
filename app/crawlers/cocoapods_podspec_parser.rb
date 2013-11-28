require 'cocoapods-core'

# Parser for CocoaPods Podspec
# this parser is only used by the CocoaPodsCrawler
#
# http://docs.cocoapods.org/specification.html
#

class CocoapodsPodspecParser

  def logger
    ActiveSupport::BufferedLogger.new("log/cocoapods.log")
  end

  # the same for all products
  attr_reader :language, :prod_type

  # the product source
  attr_reader :podspec

  # important parts of the parsed domain model output
  attr_reader :name, :prod_key, :version

  def initialize
    @language  = Product::A_LANGUAGE_OBJECTIVEC
    @prod_type = Project::A_TYPE_COCOAPODS
  end


  # Public: parses a podspec file
  #
  # file  - the Podspec file path
  #
  # Returns a Product
  def parse_file ( file )
    @podspec = load_spec file
    return nil unless @podspec

    set_prod_key_and_version

    @product = get_product
    update_product

    @product
  end


  def load_spec file
    Pod::Spec.from_file(file)
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end

  def set_prod_key_and_version
    @name     = @podspec.name
    @prod_key = @podspec.name.downcase
    @version  = @podspec.version.to_s
  end

  def get_product

    product = Product.find_by_lang_key(Product::A_LANGUAGE_OBJECTIVEC, prod_key)

    unless product
      product = Product.new
      product.update_attributes({
        :reindex       => true,
        :prod_key      => prod_key,
        :name          => name,
        :name_downcase => prod_key,
        :description   => description,

        :language      => language,
        :prod_type     => prod_type,
      })
      product.save
    end

    product
  end


  def update_product
    create_version
    create_license
    create_dependencies
    create_subspec_dependencies
    create_repository
    create_developers
    create_homepage_link
    create_github_podspec_versionarchive
    create_screenshot_links
    @product.save
    @product
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end


  def create_dependencies
    @podspec.dependencies.each do |dep|
      d = create_dependency(dep.name, dep.name.downcase, dep.requirement.to_s)
    end
  end

  def create_subspec_dependencies

    return if @podspec.subspecs.empty?

    # get all dependencies of all sub dependencies
    # TODO create scopes
    deps = @podspec.subspecs.map(&:dependencies).flatten

    #remove subspecs from dependencies
    subspec_start = "#{@podspec.name}/"
    deps.delete_if {|d| d.name.start_with? subspec_start}

    deps.each do |dep|
      d = create_dependency(dep.name, dep.name.downcase, dep.requirement.to_s)
    end

  end

  def create_dependency dep_name, dep_prod_key, dep_version
    # make sure it's really downcased
    dep_prod_key = dep_prod_key.downcase

    dep = Dependency.find_by(language, prod_key, version, dep_name, dep_version, dep_prod_key)
    return dep if dep

    dep = Dependency.new({
      :language     => language,
      :prod_type    => prod_type,
      :prod_key     => prod_key,
      :prod_version => version,

      :name         => dep_name,
      :dep_prod_key => dep_prod_key,
      :version      => dep_version,
      })
    dep.save
    dep
  end

  def create_version

    version_numbers = @product.versions.map(&:version)
    return nil if version_numbers.member? version

    @product.add_version( version )

    CrawlerUtils.create_newest @product, version
    CrawlerUtils.create_notifications @product, version
  end

  def create_license
    # create new license if version doesn't exist yet
    licenses = License.where( {:language => language, :prod_key => prod_key, :version  => version} )
    return nil if licenses.first

    license = License.new({
      :language => language,
      :prod_key => prod_key,
      :version  => version,

      :name     => @podspec.license[:type],
      :comments => @podspec.license[:text],
    })
    license.save
  end


  def create_repository
    repo = repository
    unless @product.repositories.member?( repo )
      @product.repositories.push( repo )
    end
  end

  def repository
    Repository.new({
      :repo_type => 'git',
      :repo_source => @podspec.source[:git]
      })
  end

  def create_developers
    @podspec.authors.each_pair do |name, email|
      developer = Developer.find_by( language, prod_key, version, name ).first
      next if developer

      developer = Developer.new({
        :language => language,
        :prod_key => prod_key,
        :version  => version,

        :name     => name,
        :email    => email
        })
      developer.save
    end
  end

  def create_homepage_link
    # checking for valid link is done inside create_versionlink
    Versionlink.create_versionlink(language, prod_key, version, @podspec.homepage, 'Homepage')
  end

  def create_github_podspec_versionarchive
    # checking for valid link is done inside create_versionlink
    va = Versionarchive.new({
      language: language,
      prod_key: prod_key,
      version_id: version,
      link:"https://github.com/CocoaPods/Specs/blob/master/#{name}/#{version}/#{name}.podspec",
      name:"#{name}.podspec (#{version})",
    })
    va.save
  end

  def create_screenshot_links
    @podspec.screenshots.to_enum.with_index(1).each do |img_url, i|
      Versionlink.create_versionlink(language, prod_key, version, img_url, "Screenshot #{i}")
    end
  end

  def description
    description = @podspec.summary
    if @podspec.description
      description << "\n\n" << @podspec.description
    end
    description
  end

end
