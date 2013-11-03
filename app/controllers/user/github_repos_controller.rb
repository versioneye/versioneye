class User::GithubReposController < ApplicationController

  before_filter :authenticate

  def init
    render "init", layout: "application"
  end

  def index
    repos = []

    if current_user.github_repos.all.count == 0
      Rails.logger.debug("Going to fill GithubRepo cache for user: #{current_user.fullname} (id: #{current_user.id.to_s})")
      github_repos = GitHubService.cached_user_repos(current_user)
    else
      github_repos = current_user.github_repos.all
    end

    github_repos = github_repos.desc(:updated_at)
    github_repos.each do |repo|
      repos << process_repo(repo)
    end

    render json: {
      success: true,
      repos: repos,
    }.to_json
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
  end

  def fetch_all
    current_user
    GithubRepo.by_user(current_user).delete_all
    GitHubService.cached_user_repos(current_user)
    render json: {changed: true, success: true}
  end

  def update
    if params[:github_id].nil? and params[:fullname].nil?
      logger.error "Unknown data object - don't satisfy githubrepo model."
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
    if params[:command].nil? or params[:fullname].nil? or params[:command_data].nil?
      error_msg = "Wrong command (`#{params[:command]}`) or project fullname is missing."
      render text: error_msg, status: 400
      return false
    end

    command_data = params[:command_data]

    case params[:command]
    when "import"
      project_name = params[:fullname]
      branch       = command_data.has_key?(:githubBranch) ? command_data[:githubBranch] : "master"
      project      = ProjectService.import_from_github( current_user, project_name, branch )
      p "#-- project: #{project}"
      if project.nil?
        error_msg = "Can't save project"
        Rails.logger.error("#{project_name} - #{error_msg}")
        render text: error_msg, status: 503 and return
      end
      if project.is_a?(String)
        error_msg = project
        Rails.logger.error("#{project_name} - #{error_msg}")
        render text: error_msg, status: 503 and return
      end

      command_data[:githubProjectId] = project[:_id].to_s
      repo = GithubRepo.find(params[:_id])
      repo = process_repo(repo)
    when "remove"
      id = command_data[:githubProjectId]

      if Project.where(_id: id).exists?
        ProjectService.destroy id
        repo = GithubRepo.find(params[:_id])
        repo = process_repo(repo)
      else
        error_msg = "Can't remove project with id: `#{id}` - it doesnt exist. Please refresh page."
        Rails.logger.error error_msg
        render text: error_msg, status: 400 and return
      end
    end

    repo[:command_data] = command_data
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

  def show_menu_items
    menu_items = []
    user_orgs = current_user.github_repos.distinct(:owner_login)
    user_orgs.each do |owner_login|
      repo = current_user.github_repos.by_owner_login(owner_login).first
      menu_items << {
        name: repo[:owner_login],
        type: repo[:owner_type]
      }
    end
    render json: menu_items
  end

  def poll_changes
    is_changed = Github.user_repos_changed?( current_user )
    if is_changed == true
      updated_repos = GitHubService.cached_user_repos(current_user)
      render json: {changed: true, msg: "Changed - pulled #{current_user.github_repos.all.count} repos"}
      return true
    end
    render json: {changed: false}
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
      format.html {redirect_to user_projects_path}
      format.json {
        render json: {success: success, project_id: id, msg: msg}}
    end
  end

  private
=begin
  adds additional metadata for each item in repo collection,
  for example is this project already imported etc
=end
    def process_repo repo
      imported_repos      = current_user.projects.by_source(Project::A_SOURCE_GITHUB)
      imported_repo_names = imported_repos.map(&:github_project).to_set
      supported_langs     = Github.supported_languages
      repo[:supported] = supported_langs.include? repo["language"]
      repo[:imported_files] = []

      if imported_repo_names.include?(repo["fullname"])
        imported_files = imported_repos.where(github_project: repo["fullname"])
        imported_files.each do |imported_project|
          filename = imported_project.filename
          project_info = {
            branch: imported_project[:github_branch],
            filename: filename,
            project_url: url_for(controller: 'projects', action: "show", id: imported_project.id),
            project_id:  imported_project.id,
            created_at: imported_project[:created_at]
          }
          repo[:imported_files] << project_info
        end
      end

      repo
    end
end
