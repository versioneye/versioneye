module ProjectsHelper
  
	def outdated_color(project)
		return "red" if project.out_number > 0 
		return "green"
	end

	def unknown_color(project)
		return "orange" if project.unknown_number > 0 
		return ""
	end

	def get_project_type(orig_filename)
		project_type = nil
		if orig_filename.match(/Gemfile/) or orig_filename.match(/Gemfile.lock/)
		  project_type = "RubyGems"
		elsif orig_filename.match(/requirements.txt/)
		  project_type = "PIP"
		elsif orig_filename.match(/package.json/)
		  project_type = "npm"
		elsif orig_filename.match(/composer.json/)
		  project_type = "composer"
		elsif orig_filename.match(/dependencies.gradle/) || orig_filename.match(/.gradle$/)
		  project_type = "gradle"
		elsif orig_filename.match(/pom.xml/)
		  project_type = "Maven2"
		elsif orig_filename.match(/project.clj/)
		  project_type = "Lein"
		end
		project_type
	end
  
end