class ProjectdependencyMigration

  # Migrate project_id string to project_id objectID.
  def self.set_languages
    z = 0
    Projectdependency.all.each do |dep|
      project = dep.project
      if project.nil?
        p "No project found for dep : #{dep.project_id} - #{dep.name} - #{dep.prod_key} "
        dep.remove
        next
      end
      dep.language = project.language
      dep.save
      z += 1
    end
    p "#{z} updated"
  end

  def self.update_php_prod_keys
    elements = Projectdependency.where(:prod_key => /^php\//i)
    elements.each do |element|
      element.prod_key = element.prod_key.gsub("php\/", "")
      element.save
    end
  end

  def self.update_pip_prod_keys
    elements = Projectdependency.where(:prod_key => /^pip\//i)
    elements.each do |element|
      element.prod_key = element.prod_key.gsub("pip\/", "")
      element.save
    end
  end

  def self.update_npm_prod_keys
    elements = Projectdependency.where(:prod_key => /^npm\//i)
    elements.each do |element|
      element.prod_key = element.prod_key.gsub("npm\/", "")
      element.save
    end
  end

end
