module ProjectsHelper

  def new_project_redirect
    if signed_in? && current_user.projects.empty?
      redirect_to new_user_project_path
    end
  end

  def outdated_color project
    return 'red' if project.out_number > 0
    'green'
  end

  def unknown_color project
    return 'orange' if project.unknown_number > 0
    ''
  end

  def add_dependency_classes project
    return nil if project.nil?
    deps = project.dependencies
    return project if deps.nil? or deps.empty?
    deps.each do |dep|
      if dep.unknown?
        dep[:status_class] = 'info'
        dep[:status_rank] = 4
      elsif dep.outdated and dep.release? == false
        dep[:status_class] = 'warn'
        dep[:status_rank] = 2
      elsif dep.outdated and dep.release? == true
        dep[:status_class] = 'error'
        dep[:status_rank] = 1
      else
        dep[:status_class] = 'success'
        dep[:status_rank] = 3
      end
    end
    project
  end

end
