class ServicesController < ApplicationController

	def index
		@project = Project.new
		render :layout => 'application_lp'
	end

	def create
		file = params[:upload]

		if (file.nil? || file.empty?)
		  flash[:error] = "No file selected. Please select a file from your computer."
		  redirect_to services_path
		  return nil
		end

		orig_filename =  file['datafile'].original_filename
		filename = nil
		filename = upload_to_s3( params )
		url = get_s3_url( filename )
		
		project_type = get_project_type( url )
		
		project = Project.create_from_file(project_type, url)
		project.name = create_random_value
		project.project_type = project_type
		project.url = url
		project.s3_filename = filename
		project.s3 = true

		if !project.dependencies.nil? && !project.dependencies.empty? && project.save
		  project.dependencies.each do |dep|
		    dep.project_id = project.id.to_s
		    dep.save
		  end
		  flash[:info] = "File parsed successfull."
		else
		  flash[:error] = "Ups. An error occured. Something is wrong with your file. Please contact the VersionEye Team by using the Feedback button."
		end
		redirect_to service_path(project.id)
	rescue => e
    	p "ERROR Message:   #{e.message}"
    	p "ERROR backtrace: #{e.backtrace}"
	end

	def show
		id = params[:id]
		@project = Project.find_by_id(id)
	end

end