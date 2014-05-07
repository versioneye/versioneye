require 'cocoapods-core'

# Parser for CocoaPods Podspec
# this parser is only used by the CocoaPodsCrawler
#
# http://docs.cocoapods.org/specification.html
#
class CocoapodsPodspecParser

  def logger
    ActiveSupport::BufferedLogger.new('log/cocoapods.log')
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

    deps = get_podspec_dependencies

    hash = hash_of_dependencies_to_versions(deps)

    hash.each_pair do |spec, version|
      create_dependency(spec, version)
    end

  end

  # returns a list of dependencies
  def get_podspec_dependencies
    subspecs = @podspec.subspecs || []

    # get all dependencies of all sub dependencies
    sub_deps = subspecs.map(&:dependencies).flatten

    # remove subspecs from dependencies
    # (for when a subspec depends on other parts of the spec)
    subspec_start = "#{@podspec.name}/"
    sub_deps.delete_if {|d| d.name.start_with? subspec_start}

    podspec.dependencies.concat(sub_deps)
  end

  # creates a hash where every key is a dependency and the value is the version
  def hash_of_dependencies_to_versions deps
    hash_array = deps.map do |dep|
      hash = {name: dep.name, version: dep.requirement.as_list}
      hash[:spec], hash[:subspec] = CocoapodsPackageManager.spec_subspec( dep.name )
      hash
    end

    specs = ( hash_array.map { |hash| hash[:spec] } ).uniq
    hash_array.inject({}) do |result,hash|
      spec = hash[:spec]
      if specs.member? spec
        result[spec] = hash[:version]
        specs.delete spec
      end
      result
    end
  end


  def create_dependency dep_name, dep_version
    # make sure it's really downcased
    dep_prod_key = dep_name.downcase
    dependency_version = dep_version.is_a?(Array) ? dep_version.first : dep_version.to_s

    dependency = Dependency.find_by(language, prod_key, version, dep_name, dependency_version, dep_prod_key)
    return dependency if dependency

    dependency = Dependency.new({
      :language     => language,
      :prod_type    => prod_type,
      :prod_key     => prod_key,
      :prod_version => version,

      :name         => dep_name,
      :dep_prod_key => dep_prod_key,
      :version      => dependency_version,
      })
    dependency.save
    dependency
  end

  def create_version
    # versions aren't stored at product
    # this is what ProductService.update_version_data does
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
      :repotype => 'git',
      :src => @podspec.source[:git]
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
    archive = Versionarchive.new({
      language: language,
      prod_key: prod_key,
      version_id: version,
      link: "#{Settings.instance.cocoapods_spec_url}/blob/master/#{name}/#{version}/#{name}.podspec",
      name: "#{name}.podspec",
    })
    Versionarchive.create_archive_if_not_exist( archive )
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
