class DependencyMigration

  def self.update_known
    Dependency.where(:known => nil).each do |dep|
      dep.update_known
      Rails.logger.info "#{dep.known} - #{dep.dep_prod_key} - #{dep.prod_key} - #{dep.prod_type}" if !dep.known
    end
  end

end
