module ProjectsHelper
  
	def outdated_color(project)
		return "red" if project.out_number > 0 
		return "green"
	end

	def upload_to_s3 ( params )
		fileUp = params[:upload]
		orig_filename =  fileUp['datafile'].original_filename
		fname = sanitize_filename(orig_filename)
		random = create_random_value
		filename = "#{random}_#{fname}"
		AWS::S3::S3Object.store(filename, 
			fileUp['datafile'].read, 
			Settings.s3_projects_bucket, 
			:access => :private)
		filename
	end
    
	def get_s3_url filename
		url = AWS::S3::S3Object.url_for(filename, Settings.s3_projects_bucket, :authenticated => true)
		url
	end

	def delete_from_s3 filename
		AWS::S3::S3Object.delete filename, Settings.s3_projects_bucket
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
		p "get project type: filename: #{orig_filename}"
		project_type = "Maven2"
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