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

end