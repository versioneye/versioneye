module ProjectsHelper
  
	def outdated_color(project)
		return "red" if project.out_number > 0 
		return "green"
	end

	def get_project_type(orig_filename)
		project_type = nil
		if orig_filename.match(/Gemfile/)
		  project_type = "RubyGems"
		elsif orig_filename.match(/requirements.txt/)
		  project_type = "PIP"
		elsif orig_filename.match(/package.json/)
		  project_type = "npm"
		elsif orig_filename.match(/composer.json/)
		  project_type = "composer"
		elsif orig_filename.match(/pom.xml/)
		  project_type = "Maven2"
		end
		project_type
	end
  
end