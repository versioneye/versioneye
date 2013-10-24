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


    v = attr["version"]
    version = Version.new({
      :version => v, 
      :license => attr["license"]["type"],
      # TODO
      #:released_at =>  
      })

    authors = attr["authors"] 
    authors.each do |name, email|
      author = Developer.new({
        :language => @@language,
        :prod_key => prod_key,
        :version  => v,

        :name     => name,
        :email    => email,  
        })
      author.save
    end

    product.description = spec.summary
    product.authors = [*spec.author].concat(spec.authors).join(', ')

    product.save
  end

  def update_dependencies product, spec

  end

end