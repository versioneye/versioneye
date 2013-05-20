module ProjectsHelper

  def new_project_redirect
    if signed_in? && current_user.projects.empty?
      redirect_to new_user_project_path
    end
  end

	def outdated_color(project)
		return "red" if project.out_number > 0
		return "green"
	end

	def unknown_color(project)
		return "orange" if project.unknown_number > 0
		return ""
	end

end
