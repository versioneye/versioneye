class DependencyMigration

  def self.update_known
    Dependency.where(:known => nil).each do |dep|
      dep.update_known
      Rails.logger.info "#{dep.known} - #{dep.dep_prod_key} - #{dep.prod_key} - #{dep.prod_type}" if dep.known == false
    end
  end

  def self.update_php_prod_keys
    elements = Dependency.where(:prod_key => /^php\//i)
    elements.each do |element|
      element.prod_key = element.prod_key.gsub("php\/", "")
      element.save
    end
    elements = Dependency.where(:dep_prod_key => /^php\//i)
    elements.each do |element|
      element.dep_prod_key = element.dep_prod_key.gsub("php\/", "")
      element.save
    end
  end

end
