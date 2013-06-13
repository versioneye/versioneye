class User::GithubReposController < ApplicationController

  before_filter :authenticate

  def index
    repos = []
    org_id = params["org_id"]
    github_repos = current_user.github_repos.all
    if org_id.nil? or org_id == "user"
      github_repos = github_repos.by_owner_type("user")
    else
      github_repos = github_repos.by_owner_login(org_id)
    end

    github_repos = github_repos.asc(:language).paginate(
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
      branch = params.has_key?(:branch) ? params[:branch] : "master"
      project = ProjectService.import_from_github(current_user, project_name, branch)

      unless project.nil?
        repo = GithubRepo.find(params[:_id])
        repo = process_repo(repo)
      else
        error_msg = "Cant import given project: #{project_name}."
        Rails.logger.error error_msg
        render text: error_msg, status: 503
        return false
      end
    when "remove"
      id = params[:project_id]
      if Project.where(_id: id).exists?
        ProjectService.destroy_project id
        repo = GithubRepo.find(params[:_id])
        repo = process_repo(repo)
      else
        error_msg = "Cant remove project with id: `#{id}` - it doesnt exist. Please refresh page."
        Rails.logger.error error_msg
        render text: error_msg, status: 400
        return false
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
    is_changed = Github.user_repos_changed?(current_user)
    p "Has changed? ",  is_changed
    if is_changed == true
      updated_repos = GitHubService.cached_user_repos(current_user)
      render json: {changed: true,
                    msg: "Changed - pulled #{current_user.github_repos.all.count} repos"}
      return true
    end
    render json: {changed: false}
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
=begin
  adds additional data for each item in repo collection,
  for example is this project already imported etc
=end
    def process_repo repo
      imported_repos = current_user.projects.by_source(Project::A_SOURCE_GITHUB)
      imported_repo_names  = imported_repos.map(&:github_project).to_set
      supported_langs = Github.supported_languages

      repo[:supported] = supported_langs.include? repo["language"]
      repo[:imported] = imported_repo_names.include? repo["fullname"]
      if repo[:imported]
        project_id = imported_repos.where(github_project: repo["fullname"]).first.id
        repo[:project_url] = url_for(controller: 'projects', action: "show", id: project_id)
        repo[:project_id] = project_id
      else
        repo[:project_url] = nil
        repo[:project_id] = nil
      end

      repo
    end
end
