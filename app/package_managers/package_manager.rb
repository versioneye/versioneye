class PackageManager

  def self.update_requested_with_current( project_dependency, product )
    if product && product.version
      project_dependency.version_requested = product.version
    else
      project_dependency.version_requested = 'UNKNOWN'
    end
    project_dependency
  end

end
