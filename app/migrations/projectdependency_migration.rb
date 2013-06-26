class ProjectdependencyMigration

  # Migrate project_id string to project_id objectID.
  def self.set_languages
    z = 0
    Projectdependency.all.each do |dep|
      project = dep.project
      if project.nil?
        p "No project found for dep : #{dep.project_id} - #{dep.name} - #{dep.prod_key} "
        next
      end
      dep.language = project.language
      dep.save
      z += 1
    end
    p "#{z} updated"
  end

end
