module ProjectsHelper

  def new_project_redirect
    if signed_in? && current_user.projects.empty?
      redirect_to new_user_project_path
    end
  rescue => e
    Rails.logger.error e.message
    nil
  end

  def outdated_color project
    return 'red' if project.out_number.to_i > 0
    'green'
  end

  def unknown_color project
    return 'orange' if project.unknown_number.to_i > 0
    'green'
  end

  def licenses_red_color project
    return 'red' if project.licenses_red.to_i > 0
    'green'
  end

  def licenses_unknown_color project
    return 'orange' if project.licenses_unknown.to_i > 0
    'green'
  end

  def path_to_stash_file project
    repo = project.scm_fullname.gsub("/", "/repos/")
    branch = URI.encode("refs/heads/#{project.scm_branch}")
    "#{Settings.instance.stash_base_url}/projects/#{repo}/browse/#{project.filename}?at=#{branch}"
  end

  def path_to_bitbucket_branch project
    "https://bitbucket.org/#{project.scm_fullname}/branch/#{project.scm_branch}"
  end

  def path_to_github_branch project
    "#{Settings.instance.github_base_url}/#{project.scm_fullname}/tree/#{project.scm_branch}"
  end

  def path_to_github_file project
    "#{Settings.instance.github_base_url}/#{project.scm_fullname}/blob/#{project.scm_branch}/#{project.filename}"
  end

  def add_dependency_classes project
    return nil if project.nil?

    deps = project.dependencies
    return project if deps.nil? or deps.empty?

    out_number = 0
    unknown_number = 0

    deps.each do |dep|
      if dep.unknown?
        dep[:status_class] = 'info'
        dep[:status_rank] = 4
        unknown_number += 1
      elsif dep.outdated and dep.release? == false
        dep[:status_class] = 'warn'
        dep[:status_rank] = 2
        out_number += 1
      elsif dep.outdated and dep.release? == true
        dep[:status_class] = 'error'
        dep[:status_rank] = 1
        out_number += 1
      else
        dep[:status_class] = 'success'
        dep[:status_rank] = 3
      end
    end
    project.out_number = out_number
    project.unknown_number = unknown_number
    project.save
    project
  end

end
