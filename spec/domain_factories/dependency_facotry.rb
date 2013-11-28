class DependencyFacotry

  def self.create_new(product, dep_product, store = true)
    dependency              = Dependency.new
    dependency.name         = dep_product.name
    dependency.version      = dep_product.version
    dependency.dep_prod_key = dep_product.prod_key
    dependency.scope        = Dependency::A_SCOPE_COMPILE
    dependency.prod_key     = product.prod_key
    dependency.prod_version = product.version
    dependency.prod_type    = dep_product.prod_type
    dependency.language     = dep_product.language
    if store
      dependency.save
    end
    dependency
  end

end
