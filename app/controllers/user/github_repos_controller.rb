class User::GithubReposController < ApplicationController

  before_filter :authenticate

  def init
    render "init", layout: "application"
  end


  def index
    task_status  = GitHubService.cached_user_repos current_user
    github_repos = current_user.github_repos
    if github_repos && github_repos.count > 0
      github_repos = github_repos.desc(:commited_at)
      repos = []
      github_repos.each do |repo|
        repos << process_repo(repo, task_status)
      end
    end
    render json: {
      success: true,
      task_status: task_status,
      repos: repos,
    }.to_json
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    render text: "An error occured. We are not able to import GitHub repositories. Please contact the VersionEye team.", status: 503
  end


  def show
    id = params[:id]
    repo = GithubRepo.where(_id: id.to_s).first
    if repo
      render json: process_repo(repo)
    else
      render text: "No such GitHub repository with id: `#{id}`", status: 400
    end
  end


  def show_menu_items
    menu_items = []
    user_orgs  = current_user.github_repos.distinct(:owner_login)
    user_orgs.each do |owner_login|
      repo = current_user.github_repos.by_owner_login(owner_login).first
      menu_items << {
        name: repo[:owner_login],
        type: repo[:owner_type]
      }
    end
    render json: menu_items
  end


=begin
  Unified updated method for GithubRepos.
  If command attr in model is "import", then imports new project from github.
  If commant attr in model is "remove", then removes current project
=end
  def create
    if params[:command].nil? || params[:fullname].nil? || params[:command_data].nil?
      error_msg = "Wrong command (`#{params[:command]}`) or project fullname is missing."
      render text: error_msg, status: 400
      return false
    end

    repo = []
    command_data = params[:command_data]
    project_name = params[:fullname]
    branch       = command_data.has_key?(:githubBranch) ? command_data[:githubBranch] : "master"
    filename     = command_data[:githubFilename]
    branch_files = params[:project_files][branch]

    case params[:command]
    when "import"
      repo = import_repo(command_data, project_name, branch, filename, branch_files)
    when "remove"
      repo = remove_repo(command_data, project_name, branch, filename, branch_files)
    when "update"
      repo = update_repo(command_data)
    end
    render json: repo
  rescue => e
    Rails.logger.error "Error in create: #{e.message}"
    Rails.logger.error e.backstrace.join('\n')
    render text: e.message, status: 503 and return
  end


  def update
    if params[:github_id].nil? and params[:fullname].nil?
      logger.error "Unknown data object - don't satisfy githubrepo model."
      render nothing: true, status: 400
    end
    redirect_to action: create
  end


  def destroy
    id = params[:project_id]
    success = false
    msg = ""
    if Project.where(_id: id).exists?
      ProjectService.destroy id
      success = true
    else
      msg = "Can't remove project with id: `#{id}` - it doesnt exist. Please refresh page."
      Rails.logger.error msg
    end
    respond_to do |format|
      format.html { redirect_to user_projects_path }
      format.json { render json: {success: success, project_id: id, msg: msg} }
    end
  end


  def poll_changes
    is_changed = Github.user_repos_changed?( current_user )
    if is_changed == true
      render json: {changed: true, msg: "Changed."}
      return true
    end
    render json: {changed: false}
  end


  def clear
    results = GithubRepo.by_user( current_user ).delete_all
    render json: {success: !results.nil?, msg: "Cache is cleaned. Ready for import."}
  end


  private


    def import_repo(command_data, project_name, branch, filename, branch_files)
      matching_files = branch_files.keep_if {|file| file['path'] == filename}
      url            = matching_files.first[:url] unless matching_files.empty?
      project        = ProjectService.import_from_github current_user, project_name, filename, branch, url

      if project.nil?
        raise "Something went wrong. It was not possible to save the project. Please contact the VersionEye team."
      end

      if project.is_a? String
        raise project
      end

      command_data[:githubProjectId] = project[:_id].to_s
      repo = GithubRepo.find(params[:_id])
      repo = process_repo(repo)
      repo[:command_data] = command_data
      repo[:command_result] = {
        project_id: project[:_id].to_s,
        filename: filename,
        branch: branch,
        repo: project_name,
        project_url: url_for(controller: 'projects', action: "show", id: project.id),
        created_at: project[:created_at]
      }
      repo
    end


    def remove_repo(command_data, project_name, branch, filename, branch_files)
      id = command_data[:githubProjectId]
      project_exists = Project.where(_id: id).exists?

      if !project_exists
        raise "Can't remove project with id: `#{id}` - it does not exist. Please refresh the page."
      end

      ProjectService.destroy id
      repo = GithubRepo.find(params[:_id])
      repo = process_repo(repo)
      repo[:command_data] = command_data
      repo[:command_result] = {
        filename: filename,
        branch: branch,
        repo: project_name
      }
      repo
    end


    def update_repo(command_data)
      Rails.logger.debug "Going to update repo-info for #{command_data}"
      repo = GitHubService.update_repo_info current_user, command_data["repoFullname"]
      repo = process_repo(repo)
      repo[:command_data] = command_data
      repo[:command_result] = {
        status: "updated"
      }

      repo
    end

=begin
  adds additional metadata for each item in repo collection,
  for example is this project already imported etc
=end
    def process_repo(repo, task_status = nil)
      imported_repos      = current_user.projects.by_source(Project::A_SOURCE_GITHUB)
      imported_repo_names = imported_repos.map(&:github_project).to_set
      supported_langs     = Product.supported_languages.map{ |lang| lang.downcase }
      repo[:supported] = supported_langs.include? repo["language"]
      repo[:imported_files] = []

      if imported_repo_names.include?(repo["fullname"])
        imported_files = imported_repos.where(github_project: repo["fullname"])
        imported_files.each do |imported_project|
          filename = imported_project.filename
          project_info = {
            repo: repo["fullname"],
            branch: imported_project[:github_branch],
            filename: filename,
            project_url: url_for(controller: 'projects', action: "show", id: imported_project.id),
            project_id:  imported_project.id,
            created_at: imported_project[:created_at]
          }
          repo[:imported_files] << project_info
        end
      end
      repo['project_files'] = decode_branch_names(repo['project_files'])
      repo['task_status'] = task_status
      repo
    end


    #function that decodes encoded branch-keys to plain string
    def decode_branch_names(project_files)
      return if project_files.nil?
      decoded_map = {}
      project_files.each_pair do |branch, files|
        decoded_branch = Github.decode_db_key(branch)
        decoded_map[decoded_branch] = files
      end
      decoded_map
    end

end
