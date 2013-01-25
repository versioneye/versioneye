class ServicesController < ApplicationController

	def index
		refer_name = params['refer']
		check_refer( refer_name )
		@project = Project.new
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
		filename = Project.upload_to_s3( file )
		url = Project.get_project_url_from_s3( filename )
		
		project_type = get_project_type( url )
		
		project = Project.create_from_file(project_type, url)
		project.name = Project.create_random_value
		project.project_type = project_type
		project.url = url
		project.s3_filename = filename
		project.source = "upload"
		project.make_project_key!

		if !project.dependencies.nil? && !project.dependencies.empty? && project.save
		  project.dependencies.each do |dep|
		    dep.project_id = project.id.to_s
		    dep.save
		  end
		else
		  flash[:error] = "Ups. An error occured. Something is wrong with your file."
		end
		@project_id = project.id
		redirect_to service_path( project.id )
	rescue => e
    	p "ERROR Message:   #{e.message}"
    	p "ERROR backtrace: #{e.backtrace}"
	end

	def show
		id = params[:id]
		@project = Project.find_by_id(id)
	end

	def recursive_dependencies
		id = params[:id]
		project = Project.find_by_id(id)
		dependencies = project.get_known_dependencies
		hash = Hash.new
		dependencies.each do |dep|      
			element = CircleElement.new
			element.id = dep.prod_key
			element.text = dep.name
			element.text = dep.prod_key if element.text.nil?
			if dep.version_lbl && !dep.version_lbl.empty? 
				element.text += ":#{dep.version_lbl}"
			end
			element.version = dep.version_requested
			hash[dep.prod_key] = element
		end
		circle = Product.fetch_deps(1, hash, Hash.new)
		respond_to do |format|
			format.json { 
				resp = generate_json_for_circle_from_hash(circle)
				render :json => "[#{resp}]"
			}
		end
	end

	def pricing
		@plan = current_user.plan if signed_in?
	end

	def choose_plan
		plan = params[:plan]
		cookies.permanent.signed[:plan_selected] = plan
		redirect_to signup_path
	end

	private 

		def check_refer(refer_name)
			if refer_name
				refer = Refer.get_by_name(refer_name)
				if refer
					refer.count = refer.count + 1 
					refer.save 
					cookies.permanent.signed[:veye_refer] = refer_name
				end
			end
		end

end