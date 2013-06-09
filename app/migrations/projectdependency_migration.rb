class ProjectdependencyMigration

  # Migrate project_id string to project_id objectID.
  def self.migrate_project_ids
    Projectdependency.all.each do |dep|
      dep.project
      dep.save
    end
  end

end
