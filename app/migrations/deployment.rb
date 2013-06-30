class Deployment

  def self.migrate
    self.step_1
    self.step_1
    self.update_php
    # db.products.dropIndex( { "prod_key": 1 } )
    # db.products.ensureIndex( { "prod_key": 1, "language": 1 } )
    # db.products.ensureIndex( { "prod_key": 1, "language": 1 }, { unique: true } )
  end

  def self.step_1
    p "Start ProjectdependencyMigration"
    ProjectdependencyMigration.set_languages

    p "Start VersioncommentMigration"
    VersioncommentMigration.set_languages

    p "Start VersionarchiveMigration"
    VersionarchiveMigration.set_languages

    p "Start VersionlinkMigration"
    VersionlinkMigration.set_languages

    p "Start DeveloperMigration"
    DeveloperMigration.set_languages

    p "Start NewestMigration"
    NewestMigration.set_languages
  end

  def self.step_2
    p "Start VersioncommentMigration"
    VersioncommentMigration.set_languages_slow

    p "Start VersionarchiveMigration"
    VersionarchiveMigration.set_languages_slow

    p "Start VersionlinkMigration"
    VersionlinkMigration.set_languages_slow

    p "Start DeveloperMigration"
    DeveloperMigration.set_languages_slow

    p "Start NewestMigration"
    NewestMigration.set_languages_slow
  end

  def self.update_php
    p "Update PHP prod_keys"
    ProductMigration.update_php_prod_keys

    p "Update PHP prod_keys VersionArchive"
    VersionarchiveMigration.update_php_prod_keys

    p "Update PHP prod_keys Versioncomment"
    VersioncommentMigration.update_php_prod_keys

    p "Update PHP prod_keys Versionlink"
    VersionlinkMigration.update_php_prod_keys

    p "Update PHP prod_keys Projectdependency "
    ProjectdependencyMigration.update_php_prod_keys

    p "Update PHP prod_keys Newest "
    NewestMigration.update_php_prod_keys

    p "Update PHP prod_keys Developer "
    DeveloperMigration.update_php_prod_keys

    p "Update PHP prod_keys Dependency "
    DependencyMigration.update_php_prod_keys
  end

end
