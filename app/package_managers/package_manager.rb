class PackageManager

  def self.update_requested_with_current( dependency, product )
    if product && product.version
      dependency.version_requested = product.version
    else
      dependency.version_requested = "UNKNOWN"
    end
    dependency
  end


end