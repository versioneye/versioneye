class User::GithubReposController < ApplicationController
  before_filter :authenticate

  #TODO: add organizations
  def index
    repos = []
    github_repos = GitHubService.cached_user_repos(current_user).asc(:language)
    github_repos = github_repos.paginate(
      page: (params[:page] || 1),
      per_page: (params[:per_page] || 30)
    )
    github_repos.each do |repo|
      repos << process_repo(repo)
    end

    repos.sort_by! {|repo| "%s" % repo["language"].to_s}
    paging = {
      current_page: github_repos.current_page,
      per_page: github_repos.per_page,
      total_entries: github_repos.total_entries,
      total_pages: github_repos.total_pages
    }

    render json: {
      success: true,
      repos: repos,
      paging: paging
    }.to_json
  end

  def update
    if params[:github_id].nil? and params[:fullname].nil?
      logger.error "Unknown data object - dont satisfy githubrepo model."
      render nothing: true, status: 400
    end

    redirect_to action: create
  end

=begin
  Unified updated method for GithubRepos.
  If command attr in model is "import", then imports new project from github.
  If commant attr in model is "remove", then removes current project
=end
  def create
    "unified update method for Backbone models"
    if params[:command].nil? or params[:fullname].nil?
      error_msg = "Wrong command (`#{params[:command]}`) or project fullname is missing."
      render text: error_msg, status: 400
    end

    case params[:command] 
    when "import" 
      project_name = params[:fullname]
      project = fetch_from_github_and_store project_name
      if project
        repo = GithubRepo.find(params[:_id])
        repo = process_repo(repo)
      else
        error_msg = "Cant import given project: #{project_name}."
        logger.error error_msg
        render text: error_msg, status: 503
      end
    when "remove"
      id = params[:project_id]
      if Project.where(_id: id).exists?
        ProjectService.destroy_project id
        success = true
        repo = {}
      else
        error_msg = "Cant remove project with id: `#{id}` - it doesnt exist. Please refresh page."
        Rails.logger.error error_msg
        render text: error_msg, status: 400
      end

    end
    render json: repo
 end

  def show 
    id = params[:id]
    repo = GithubRepo.where(_id: id.to_s).first
    if repo  
      render json: process_repo(repo)
    else
      error_msg = "No such github repo with id: `#{id}`"
      render text: error_msg, status: 400
    end
  end

  def destroy
    id = params[:project_id]
    success = false
    msg = ""
    if Project.where(_id: id).exists?
      ProjectService.destroy_project id
      success = true
    else
      msg = "Cant remove project with id: `#{id}` - it doesnt exist. Please refresh page."
      Rails.logger.error msg
    end
    respond_to do |format|
      format.html {redirect_to user_projects_path}
      format.json {
        render json: {success: success, project_id: id, msg: msg}}
    end
  end


  private
    #adds additional data for repos
    def process_repo repo
      imported_repos = current_user.projects.by_source(Project::A_SOURCE_GITHUB)
      imported_repo_names  = imported_repos.map(&:github_project).to_set
      supported_langs = Github.supported_languages
      
      repo[:supported] = supported_langs.include? repo["language"]
      repo[:imported] = imported_repo_names.include? repo["fullname"]
      if repo[:imported]
        project_id = imported_repos.where(github_project: repo["fullname"]).first.id
        repo[:project_url] = url_for(contoller: 'projects', action: "show", id: project_id)
        repo[:project_id] = project_id
      else
        repo[:project_url] = nil
        repo[:project_id] = nil
      end
    
      repo
    end

#TODO: refactor it to projectService - same code already exists in projects_controller
    def fetch_from_github_and_store github_project
      private_project = Github.private_repo?( current_user.github_token, github_project )
      if private_project && !is_allowed_to_add_private_project?
        flash[:error] = "You selected a private project. Please upgrade your plan to monitor the selected project."
        redirect_to settings_plans_path
        return nil
      end
      sha = Github.get_repo_sha( github_project, current_user.github_token )
      project_info = Github.repository_info( github_project, sha, current_user.github_token )
      if project_info.empty?
        flash[:error] = "We couldn't find any project file in the selected project. Please choose another project."
        return nil
      end
      file = Github.fetch_file( project_info['url'], current_user.github_token )
      s3_infos = S3.upload_github_file( file, project_info['name'] )
      project = create_project(s3_infos['s3_url'], github_project)
      project.source = Project::A_SOURCE_GITHUB
      project.s3_filename = s3_infos['filename']
      project.github_project = github_project
      project.private_project = private_project

      if store_project( project )
        return project
      end
    end

    def create_project( url, project_name )
      project = ProjectService.create_from_url( url )
      project.user_id = current_user.id.to_s
      if project.name.nil? || project.name.empty?
        project.name = project_name
      end
      project
    end

    def store_project( project )
      project.make_project_key!
      if project.dependencies && !project.dependencies.empty? && project.save
        project.save_dependencies
        flash[:success] = "Project was created successfully."
        return true
      else
        logger.error "#--------------------", "Cant save project: ", project.to_json
        logger.error project.error.full_messages.to_sentence
        flash[:error] = "Ups. An error occured. Something is wrong with your file. Please contact the VersionEye Team by using the Feedback button."
        return false
      end
    end

    def is_allowed_to_add_private_project?
      user = current_user
      private_projects = Project.find_private_projects_by_user(user.id)
      plan = user.plan
      if plan.private_projects > private_projects.count
        return true
      else
        return false
      end
    end

end
