class Deployment

  def self.migrate
    p "Start VersionarchiveMigration"
    VersionarchiveMigration.set_languages
    VersionarchiveMigration.set_languages_slow

    p "Start VersioncommentMigration"
    VersioncommentMigration.set_languages
    VersioncommentMigration.set_languages_slow

    p "Start VersionlinkMigration"
    VersionlinkMigration.set_languages
    VersionlinkMigration.set_languages_slow

    p "Start ProjectdependencyMigration"
    ProjectdependencyMigration.set_languages
  end

end
