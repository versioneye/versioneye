module ProjectsHelper
  
	def outdated_color(project)
		return "red" if project.out_number > 0 
		return "green"
	end

	def upload_to_s3( fileUp )
		orig_filename =  fileUp['datafile'].original_filename
		fname = sanitize_filename(orig_filename)
		random = create_random_value
		filename = "#{random}_#{fname}"
		AWS::S3::S3Object.store(filename, 
			fileUp['datafile'].read, 
			Settings.s3_projects_bucket, 
			:access => "private")
		filename
	end

	def sanitize_filename(file_name)
		just_filename = File.basename(file_name)
		just_filename.sub(/[^\w\.\-]/,'_')
	end

	def create_random_value
		chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
		value = ""
		20.times { value << chars[rand(chars.size)] }
		value
	end

	def get_project_type(orig_filename)
		project_type = nil
		if orig_filename.match(/Gemfile/)
		  project_type = "RubyGems"
		elsif orig_filename.match(/requirements.txt/)
		  project_type = "PIP"
		elsif orig_filename.match(/package.json/)
		  project_type = "npm"
		end
		project_type
	end
  
end