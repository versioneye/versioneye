class PomJsonParser < CommonParser

  def parse(url)
    return nil if url.nil? || url.empty?
    pom_json = self.fetch_response_body_json(url)
    return nil if pom_json.nil?
    project = init_project(url)
    pom_json['dependencies'].each do |json_dep|
      version = json_dep['version']
      name = json_dep['name']
      spliti = name.split(':')
      group_id = spliti[0]
      artifact_id = spliti[1]
      dependency = init_dependency(name, group_id, artifact_id, version)
      product = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id)
      dependency.prod_key = product.prod_key if product
      project.unknown_number += 1 if product.nil?
      project.out_number += 1 if dependency.outdated?
      project.projectdependencies.push(dependency)
    end
    project.dep_number = project.dependencies.size
    project.name = pom_json['name']
    project
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def init_dependency name, group_id, artifact_id, version
    dependency             = Projectdependency.new
    dependency.language    = Product::A_LANGUAGE_JAVA
    dependency.name        = name
    dependency.group_id    = group_id
    dependency.artifact_id = artifact_id
    dependency.version_requested = version
    dependency
  end

  def init_project( url )
    project              = Project.new
    project.project_type = Project::A_TYPE_MAVEN2
    project.language     = Product::A_LANGUAGE_JAVA
    project.url          = url
    project
  end

end
