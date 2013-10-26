require 'cocoapods-core'

# Parser for CocoaPods podspec
# http://docs.cocoapods.org/specification.html
class PodSpecParser < CommonParser

  @@language  = Product::A_LANGUAGE_OBJECTIVEC
  @@prod_type = Project::A_TYPE_COCOAPODS


  def parse( url )
    # TODO implement me!
  end

  def parse_file ( file )
    podspec = load_spec file
    product = get_product podspec
    update_product product, podspec
  end


  def load_spec file
    Pod::Spec.from_file(file)
  end


  def get_product podspec
    product = Product.find_by_lang_key(Product::A_LANGUAGE_OBJECTIVEC, podspec.name)

    unless product
      product = Product.new
      prod_key = podspec.name
      product.update_attributes({
        :reindex       => true,
        :prod_key      => prod_key,
        :name          => podspec.name,
        :name_downcase => podspec.name.downcase,
        :description   => podspec.summary,
        :language      => @@language,
        :prod_type     => @@prod_type,
      })
      product.save
    end

    product
  end


  def update_product product, podspec
    create_dependencies podspec
    product.versions.push( version(podspec) ) # TODO check if exist already
    create_repository( podspec )
    create_developers( podspec )
    create_homepage_link( podspec ) # TODO check if exist already
    product.save
    product
  end


  def create_dependencies podspec
    podspec.dependencies.each do |pod_dep|
      dep = Dependency.find_by_lang_key_and_version(@@language, podspec.name, podspec.version)
      next if dep
      dep = Dependency.new({
        :language      => @@language,
        :prod_type     => @@prod_type,
        :prod_key      => podspec.name,
        :prod_version  => podspec.version,

        :dep_prod_key  => pod_dep.to_s,
        :version       => pod_dep.version,
        })
      dep.save
    end
  end


  def version podspec
    Version.new({
      :version => podspec.version,
      :license => podspec.license[:type],
      # TODO get release date through github api
      # repository => version tag
      #:released_at =>
      })
  end


  def create_repository podspec
    repo = repository(podspec)
    unless product.repositories.member?( repo )
      product.repositories.push( repo )
    end
  end

  def repository podspec
    Repository.new({
      :repo_type => 'git',
      :repo_source => podspec.source[:git]
      })
  end

  def create_developers podspec
    podspec.authors.each do |name, email|
      developer = Developer.find_by( @@language, podspec.name, podspec.version, name )
      next if developer
      developer = Developer.new({
        :language => @@language,
        :prod_key => podspec.name,
        :version  => podspec.version,

        :name     => name,
        :email    => email
        })
      developer.save
    end
  end

  def create_homepage_link podspec
    versionlink = Versionlink.new({
      :language   => @@language,
      :prod_key   => podspec.name,
      :version_id => podspec.version,

      :name       => 'Homepage',
      :link       => podspec.homepage
      })
    versionlink.save
    versionlink
  end

end
