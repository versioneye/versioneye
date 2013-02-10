module ProjectsHelper
  
	def outdated_color(project)
		return "red" if project.out_number > 0 
		return "green"
	end

	def unknown_color(project)
		return "orange" if project.unknown_number > 0 
		return ""
	end
  
end
