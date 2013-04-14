class DependencyMigration

  def self.delete_wrong_deps(lang)
    z = 0
    Dependency.where(language: lang).each do |dep|
      re_name = dep.dep_prod_key.gsub("php/", "")
      if !re_name.eql?(dep.name)
        p "delete #{dep.name} - #{dep.dep_prod_key}"
        z = z + 1
        dep.remove
      end
    end 
    p "#{z}"
  end

  def self.update_known
    Dependency.where(:known => nil).each do |dep|
      dep.update_known
      p "#{dep.known} - #{dep.dep_prod_key} - #{dep.prod_key} - #{dep.prod_type}" if dep.known == false 
    end
  end

end