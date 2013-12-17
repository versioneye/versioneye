class GradleParser < CommonParser

  def parse(url)
    return nil if url.nil?
    content = self.fetch_response(url).body
    return nil if content.nil?

    dependecies_matcher = /
      (\w+) #scope
      [\s|\(]?[\'|\"]+ #scope separator
        ([\w|\d|\.|\-|\_]+) #group_id
        :([\w|\d|\.|\-|_]+) #artifact
        :([\w|\d|\.|\-|_]+) #version number
    /xi

    matches = content.scan( dependecies_matcher )
    deps    = self.build_dependencies(matches)
    project              = Project.new deps
    project.project_type = Project::A_TYPE_GRADLE
    project.language     = Product::A_LANGUAGE_JAVA
    project.url          = url
    project.dep_number   = project.dependencies.size
    project
  end

  def build_dependencies(matches)
    # build and initiliaze array of dependencies.
    # Arguments array of matches, should be [[scope, group_id, artifact_id, version],...]
    # Returns map {:unknowns => 0 , dependencies => []}
    data = []
    unknowns, out_number = 0, 0
    matches.each do |row|
      version = row[3]
      dependency = Projectdependency.new({
        :scope => row[0],
        :group_id => row[1],
        :artifact_id => row[2],
        :name => row[2],
        :language => Product::A_LANGUAGE_JAVA,
        :comperator => '='
      })

      product = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id)
      if product
        dependency.prod_key = product.prod_key
      else
        unknowns += 1
      end

      parse_requested_version( version, dependency, product )

      dependency.stability = VersionTagRecognizer.stability_tag_for version
      VersionTagRecognizer.remove_minimum_stability version

      out_number += 1 if dependency.outdated?
      data << dependency
    end

    {:unknown_number => unknowns, :out_number => out_number, :projectdependencies => data}
  end

  def parse_requested_version(version, dependency, product)
    if version.nil? || version.empty?
      self.update_requested_with_current(dependency, product)
      return
    end
    version = version.to_s.strip
    version = version.gsub('"', '')
    version = version.gsub("'", '')

    if product.nil?
      dependency.version_requested = version
      dependency.version_label = version

    elsif version.match(/\.\+$/i) or version.match(/\.$/i)
      # Newest available static version
      # http://www.gradle.org/docs/current/userguide/dependency_management.html#sec:dependency_resolution
      ver = version.gsub('+', '')
      starter = ver.gsub(' ', '')
      versions        = VersionService.versions_start_with( product.versions, starter )
      highest_version = VersionService.newest_version_from( versions )
      if highest_version
        dependency.version_requested = highest_version.to_s
      else
        dependency.version_requested = ver
      end
      dependency.comperator = "="
      dependency.version_label = "#{ver}+"

    else
      dependency.version_requested = version
      dependency.comperator = "="
      dependency.version_label = version

    end
  end

end
