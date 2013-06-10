class ProjectdependencyMigration

  # Migrate project_id string to project_id objectID.
  def self.migrate_project_ids
    Projectdependency.all.each do |dep|
      if dep.project_id && dep.project_id.is_a?( String )
        project = dep.project
        dep.project = project
        dep.save
      end
    end
  end

end
