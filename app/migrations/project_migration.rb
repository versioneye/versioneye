class ProjectMigration

  def self.set_languages_based_on_type
    projects = Project.all
    projects.each do |project|
      if project.project_type.eql? Project::A_TYPE_RUBYGEMS
        project.language = Product::A_LANGUAGE_RUBY
      elsif project.project_type.eql? Project::A_TYPE_PIP
        project.language = Product::A_LANGUAGE_PYTHON
      elsif project.project_type.eql? Project::A_TYPE_NPM
        project.language = Product::A_LANGUAGE_NODEJS
      elsif project.project_type.eql? Project::A_TYPE_COMPOSER
        project.language = Product::A_LANGUAGE_PHP
      elsif project.project_type.eql? Project::A_TYPE_GRADLE
        project.language = Product::A_LANGUAGE_JAVA
      elsif project.project_type.eql? Project::A_TYPE_MAVEN2
        project.language = Product::A_LANGUAGE_JAVA
      elsif project.project_type.eql? Project::A_TYPE_LEIN
        project.language = Product::A_LANGUAGE_CLOJURE
      end
      project.save
    end
  end

  def self.migrate_projects
    users = User.all
    users.each do |user|
      projects = Project.where(user_id: user.id)
      projects.each do |project|
        project.user = user
        project.save
      end
    end
  end

end
