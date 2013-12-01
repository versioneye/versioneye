class ProjectdependencyFactory

  def self.create_new(project, product, store = true)
    dependency = Projectdependency.new
    if product
      dependency.name        = product.name
      dependency.language    = product.language
      dependency.prod_key    = product.prod_key
      dependency.group_id    = product.group_id
      dependency.artifact_id = product.artifact_id
    end
    if store
      dependency.save
    end
    project.projectdependencies.push dependency
    dependency
  end

end
