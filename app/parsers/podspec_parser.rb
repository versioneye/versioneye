require 'cocoapods-core'

class PodSpecParser < CommonParser

  # Parser for CocoaPods specs

  @@language  = Product::A_LANGUAGE_OBJECTIVEC
  @@prod_type = Project::A_TYPE_COCOAPODS

  file = '/Users/anjaresmer/Code/cocoapods-specs/twitter-text-objc/1.6.1/twitter-text-objc.podspec'

  def parse ( url )
    spec = load_spec file

    prod = get_product spec
    update_product prod, spec
  end


  def load_spec file
    Pod::Spec.from_file(file)
  end

  def get_product spec
    product = Product.find_by_lang_key(Product::A_LANGUAGE_OBJECTIVEC, spec.name)

    unless product
      product = Product.new
    end

    product
  end

  def update_product product, spec

    prod_key = spec.name
    product.update_attributes({
      :reindex       => true,
      :prod_key      => prod_key,
      :name          => spec.name,
      :name_downcase => spec.name.downcase,
      :language      => @@language,
      :prod_type     => @@prod_type,
    })

    product.update_attributes()

    attr = spec.attributes_hash

    product.description = spec.summary
    product.authors = [*spec.author].concat(spec.authors).join(', ')

    product.save
  end

  def update_dependencies product, spec

  end


  def version podspec
    v = podspec["version"]
    version = Version.new({
      :version => v,
      :license => podspec["license"]["type"],
      # TODO get release date through github api
      # repository => version tag
      #:released_at =>
      })
    version.save
  end


  def repository podspec
    log
    git_repo = Repository.new({
      :repo_type => "git",
      :repo_source => podspec["source"]["git"]
      })
    git_repo.save
  end


  def developers podspec
    developers = []

    authors = [*podspec["author"]].concat( podspec["authors"] )
    authors.each do |name, email|
      developer = Developer.new({

        :language => @@language,
        :prod_key => prod_key,
        :version  => v,

        :name     => name,
        :email    => email,
        })
      developer.save
      developers << developer
    end

    developers
  end


  # TODO I just copied this and don't know how it works yet
  # dependency for project
  def init_dependency( product, pod_name )
    dependency          = Projectdependency.new
    dependency.name     = pod_name
    dependency.language = Product::A_LANGUAGE_OBJECTIVEC
    if product
      dependency.prod_key        = product.prod_key
      dependency.version_current = product.version
    end
    dependency
  end

end
