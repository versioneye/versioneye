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

  @@language  = Product::A_LANGUAGE_OBJECTIVEC
  @@prod_type = Project::A_TYPE_COCOAPODS

  attr_accessor :podspec

  def parse_file ( file )
    @podspec = load_spec file
    return nil unless @podspec

    @spec_hash = @podspec.to_hash

    @product = get_product
    update_product

    logger.info(@spec_hash.to_json) unless @spec_hash.except!("name").empty?

    @product
  end


  def load_spec file
    Pod::Spec.from_file(file)
  rescue => e
    logger.error e.message
    logger.error e.backtrace
    nil
  end


  def get_product
    @spec_hash.except! "summary", "description"

    product = Product.find_by_lang_key(Product::A_LANGUAGE_OBJECTIVEC, prod_key)

    unless product
      product = Product.new
      product.update_attributes({
        :reindex       => true,
        :prod_key      => prod_key,
        :name          => @podspec.name,
        :name_downcase => prod_key,
        :description   => description,
        :language      => @@language,
        :prod_type     => @@prod_type,
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
    create_screenshot_links
    @product.save
    @product
  rescue => e
    logger.error e.message
    logger.error e.backtrace
    nil
  end


  def create_dependencies
    @spec_hash.except! *(%w{
      dependencies
      platforms
      requires_arc
      frameworks
      ios
      osx
      resources
      subspecs
      default_subspec
      vendored_libraries
      source_files
      exclude_files
      compiler_flags
      xcconfig
      preserve_paths
      public_header_files
      prefix_header_contents
      header_mappings_dir
      prepare_command
      })

    @podspec.dependencies.each do |pod_dep|
      dep = Dependency.find_by_lang_key_and_version(@@language, prod_key, version)
      next if dep
      dep = Dependency.new({
        :language      => @@language,
        :prod_type     => @@prod_type,
        :prod_key      => prod_key,
        :prod_version  => version,

        :dep_prod_key  => pod_dep.to_s,
        :version       => pod_dep.version,
        })
      dep.save
    end
  end

  def create_version
    @spec_hash.except! "version"

    version_numbers = @product.versions.map(&:version)
    return nil if version_numbers.member? version

    @product.add_version( version )

    CrawlerUtils.create_newest @product, version
    CrawlerUtils.create_notifications @product, version
  end

  def create_license
    @spec_hash.except! "license"

    # create new license if version doesn't exist yet
    licenses = License.where( {:language => @@language, :prod_key => prod_key, :version  => version} )
    return nil if licenses.first

    license = License.new({
      :language => @@language,
      :prod_key => prod_key,
      :version  => version,

      :name     => @podspec.license[:type],
      :comments => @podspec.license[:text],
    })
    license.save
  end


  def create_repository
    @spec_hash.except! "source"

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
    @spec_hash.except! "authors"

    @podspec.authors.each do |name, email|
      developer = Developer.find_by( @@language, prod_key, version, name ).first
      next if developer

      developer = Developer.new({
        :language => @@language,
        :prod_key => prod_key,
        :version  => version,

        :name     => name,
        :email    => email
        })
      developer.save
    end
  end

  def create_homepage_link
    @spec_hash.except! "homepage"
    Versionlink.create_versionlink(@@language, prod_key, version, @podspec.homepage, 'Homepage')
  end

  def create_screenshot_links
    @spec_hash.except! "screenshots"

    @podspec.screenshots.to_enum.with_index(1).each do |img_url, i|
      Versionlink.create_versionlink(@@language, prod_key, version, img_url, "Screenshot #{i}")
    end
  end

  def prod_key
    @podspec.name.downcase
  end

  def version
    @podspec.version.to_s
  end

  def description
    @spec_hash.except! "summary", "description"

    description = @podspec.summary
    if @podspec.description
      description << "\n\n" << @podspec.description
    end
    description
  end

end
