module ProjectsHelper

  def jvm_project? project
    return false if project.nil? || project.language.to_s.empty?

    project.language.eql?( Product::A_LANGUAGE_JAVA ) ||
    project.project_type.to_s.eql?(Project::A_TYPE_MAVEN2) ||
    project.project_type.to_s.eql?(Project::A_TYPE_SBT) ||
    project.project_type.to_s.eql?(Project::A_TYPE_GRADLE)
  end

  def has_jvm_ve_plugin? project
    return true if project.dependencies.where(:artifact_id => "versioneye-maven-plugin").count > 0
    return true if project.dependencies.where(:artifact_id => "sbt-versioneye-plugin").count > 0
    return true if project.dependencies.where(:artifact_id => "gradle-versioneye-plugin").count > 0
    return true if project.dependencies.where(:name => "versioneye-maven-plugin").count > 0
    return true if project.dependencies.where(:name => "sbt-versioneye-plugin").count > 0
    return true if project.dependencies.where(:name => "gradle-versioneye-plugin").count > 0
    project.children.each do |child|
      return true if child.dependencies.where(:artifact_id => "versioneye-maven-plugin").count > 0
      return true if child.dependencies.where(:artifact_id => "sbt-versioneye-plugin").count > 0
      return true if child.dependencies.where(:artifact_id => "gradle-versioneye-plugin").count > 0
      return true if child.dependencies.where(:name => "versioneye-maven-plugin").count > 0
      return true if child.dependencies.where(:name => "sbt-versioneye-plugin").count > 0
      return true if child.dependencies.where(:name => "gradle-versioneye-plugin").count > 0
    end
    false
  end


  def security_available?( project )
    return false if project.nil?

    project.language.eql?(Product::A_LANGUAGE_PHP) ||
    project.language.eql?(Product::A_LANGUAGE_NODEJS) ||
    project.language.eql?(Product::A_LANGUAGE_JAVASCRIPT) ||
    project.language.eql?(Product::A_LANGUAGE_ACTIONSCRIPT) ||
    project.language.eql?(Product::A_LANGUAGE_TYPESCRIPT) ||
    project.language.eql?(Product::A_LANGUAGE_LIVESCRIPT) ||
    project.language.eql?(Product::A_LANGUAGE_PURESCRIPT) ||
    project.language.eql?(Product::A_LANGUAGE_HTML) ||
    project.language.eql?(Product::A_LANGUAGE_CSS) ||
    project.language.eql?(Product::A_LANGUAGE_JAVA) ||
    project.language.eql?(Product::A_LANGUAGE_PYTHON) ||
    project.language.eql?(Product::A_LANGUAGE_CSHARP) ||
    project.language.eql?(Product::A_LANGUAGE_RUBY)
  end

  def outdated_color project
    return 'red' if project[:out_number_sum].to_i > 0
    'green'
  end

  def unknown_color project
    return 'orange' if project[:unknown_number_sum].to_i > 0
    'green'
  end

  def licenses_red_color project
    return 'red' if project[:licenses_red_sum].to_i > 0
    'green'
  end

  def licenses_color sum
    return 'red' if sum.to_i > 0
    'green'
  end

  def licenses_unknown_color project
    return 'orange' if project[:licenses_unknown_sum].to_i > 0
    'green'
  end

  def subproject_label_color selected_id, sub_id
    return 'success' if selected_id.eql?('summary')
    return 'success' if selected_id.eql?(sub_id)
    'default'
  end

  def subproject_name( project )
    name = project.filename
    if name.to_s.empty?
      name = project.name
    end
    name
  end

  def path_to_stash_file project
    repo = project.scm_fullname.gsub("/", "/repos/")
    branch = URI.encode("refs/heads/#{project.scm_branch}")
    "#{Settings.instance.stash_base_url}/projects/#{repo}/browse/#{project.filename}?at=#{branch}"
  end

  def path_to_bitbucket_branch project
    "https://bitbucket.org/#{project.scm_fullname}/branch/#{project.scm_branch}"
  end

  def path_to_bitbucket_file project
    "https://api.bitbucket.org/1.0/repositories/#{project.scm_fullname}/raw/#{project.scm_revision}/#{project.filename}"
  end

  def path_to_github_branch project
    "#{Settings.instance.github_base_url}/#{project.scm_fullname}/tree/#{project.scm_branch}"
  end

  def path_to_github_file project
    "#{Settings.instance.github_base_url}/#{project.scm_fullname}/blob/#{project.scm_branch}/#{project.filename}"
  end

  def project_member?(project, user)
    return false if project.nil?
    return false if user.nil?

    return true if user.admin == true
    return true if project.user && project.user.ids.eql?( user.ids )
    return true if project.is_collaborator?( user )

    parent_project = project.parent
    if parent_project
      return true if parent_project.user.ids.eql?( user.ids )
      return true if parent_project.is_collaborator?( user )
    end

    return false
  end


  def sort_hash_deps dependencies
    dependencies.sort_by {|dep| dep[:status_rank].to_i }
  rescue
    logger.error "ERROR in sort_hash_deps: #{e.message}"
    logger.error e.stacktrace.join "\n"
    dependencies
  end


  def sort_deps dependencies
    dependencies.sort_by {|dep| dep.status_rank.to_i }
  rescue
    logger.error "ERROR in sort_deps: #{e.message}"
    logger.error e.stacktrace.join "\n"
    dependencies
  end


  def add_dependency_classes project
    return nil if project.nil?

    deps = nil
    if project.is_a? Hash
      deps = project[:dependencies]
    else
      deps = project.dependencies
    end
    return project if deps.nil? or deps.empty?

    add_status_to_deps deps
    project
  rescue => e
    logger.error "ERROR in add_dependency_classes: #{e.message}"
    logger.error e.stacktrace.join "\n"
  end


  def add_status_to_deps dependencies
    dependencies.each do |dep|
      add_status_to_dep( dep )
    end
  end


  def add_status_to_dep dep
    return nil if dep.nil?
    return nil if dep.respond_to?("status_class") && !dep.status_class.to_s.empty?

    if dep.unknown?
      dep[:status_class] = 'info'
      dep[:status_rank]  = 3
      dep.status_class   = 'info' if dep.respond_to?("status_class")
      dep.status_rank    = 3 if dep.respond_to?("status_rank")
    elsif dep.outdated and dep.release? == false
      dep[:status_class] = 'warning'
      dep[:status_rank]  = 2
      dep.status_class   = 'warning' if dep.respond_to?("status_class")
      dep.status_rank    = 2 if dep.respond_to?("status_rank")
    elsif dep.outdated and dep.release? == true
      dep[:status_class] = 'error'
      dep[:status_rank]  = 1
      dep.status_class   = 'error' if dep.respond_to?("status_class")
      dep.status_rank    = 1 if dep.respond_to?("status_rank")
    else
      dep[:status_class] = 'success'
      dep[:status_rank]  = 4
      dep.status_class   = 'success' if dep.respond_to?("status_class")
      dep.status_rank    = 4 if dep.respond_to?("status_rank")
    end
    dep.save
  end


  def merge_to_projects project
    if project.organisation
      projects = Project.where(:organisation_id => project.organisation.ids, :parent_id => nil)
      return merge_to_user_or_orga_projects project, projects
    else
      return merge_to_user_or_orga_projects project, current_user.projects.where(:parent_id => nil)
    end
  end

  def merge_to_user_or_orga_projects project, projects
    projs = []
    parents = []
    singles = []
    projects.each do |pro|
      next if pro.id.to_s.eql?(project.id.to_s)

      if pro.child_count.to_i > 0
        pro.has_kids = 1
        parents << pro
      else
        pro.has_kids = 0
        singles << pro
      end
    end
    parents = parents.sort_by {|obj| obj.name}
    singles = singles.sort_by {|obj| obj.name}
    projs << parents
    projs << singles
    projs.flatten
  end

end
