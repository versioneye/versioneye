class User::GithubReposController < User::ScmReposController

  before_filter :authenticate


  def index
    status_message = ''
    status_success = true
    task_status = ''

    if current_user.github_token.nil?
      status_message = 'Your VersionEye account is not connected to GitHub.'
      status_success = false
      task_status = GitHubService::A_TASK_DONE
    else
      task_status  = GitHubService.cached_user_repos current_user
      github_repos = current_user.github_repos
      if github_repos && github_repos.count > 0
        github_repos = github_repos.desc(:commited_at)
      end

      if task_status == GitHubService::A_TASK_DONE and github_repos.count == 0
        status_message = %w{
          We couldn't find any repositories in your GitHub account.
          If you think that's an error contact the VersionEye team.
        }.join(' ')
        status_success = false
        task_status = GitHubService::A_TASK_DONE
      end
    end

    render json: {
      success: status_success,
      task_status: task_status,
      repos: github_repos,
      message: status_message
    }.to_json
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    render text: 'An error occured. We are not able to import GitHub repositories. Please contact the VersionEye team.', status: 503
  end


  def show
    owner = params[:owner]
    repo  = params[:repo]
    fullname = "#{owner}/#{repo}"
    @repo = current_user.github_repos.by_fullname( fullname ).first
  end


  def reimport
    owner = params[:owner]
    repo  = params[:repo]
    fullname = "#{owner}/#{repo}"
    repos = GithubRepo.by_user( current_user ).by_fullname( fullname )
    repos.each do |repo|
      repo.branches = nil
      repo.project_files = nil
      repo.save
    end
    redirect_to :back
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  end


  def repo_files
    task_status = ''
    owner = params[:owner]
    repo  = params[:repo]
    fullname = "#{owner}/#{repo}"
    repo = current_user.github_repos.by_fullname( fullname ).first
    task_status = GitHubService.status_for current_user, repo
    processed_repo = process_repo( repo )

    render json: {
      task_status: task_status,
      repo: processed_repo
    }.to_json
  end


  def clear
    results = GithubRepo.by_user( current_user ).delete_all
    flash[:success] = "Cache is cleaned. Ready to re-import."
    redirect_to :back
  end


  private


    def clear_import_cache project 
      key = "github:::#{current_user.username}:::#{project.scm_fullname}:::#{project.filename}:::#{project.scm_branch}"
      ProjectService.cache.delete key 
    end


    def import_repo(project_name, branch, filename)
      project_id = ''
      project_url = ''
      status = ProjectImportService.import_from_github_async current_user, project_name, filename, branch
      if status && status.match(/\Adone_/)
        project_id = status.gsub("done_", "")
        project = Project.find project_id 
        project_url = url_for(controller: 'projects', action: "show", id: project.id) 
        status = 'done'
      elsif status && status.match(/\Aerror_/)
        return status.gsub("error_", "")
      end
      
      {
        repo: project_name,
        filename: filename,
        branch: branch,
        status: status,
        project_id: project_id,
        project_url: project_url
      }
    rescue => e 
      Rails.logger.error e.message 
      Rails.logger.error e.backtrace.join "\n"
      "Something went wrong. Please contact the VersionEye Team."
    end


    def update_repo( command_data )
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
      imported_repo_names = imported_repos.map(&:scm_fullname).to_set
      supported_langs     = Product::A_LANGS_SUPPORTED.map{ |lang| lang.downcase }
      repo[:supported] = supported_langs.include? repo[:language]
      repo[:imported_files] = []

      if imported_repo_names.include?(repo[:fullname])
        imported_files = imported_repos.where(scm_fullname: repo[:fullname])
        imported_files.each do |imported_project|
          filename = imported_project.filename
          project_info = create_project_info( repo, imported_project )
          repo[:imported_files] << project_info
        end
      end
      repo['project_files'] = decode_branch_names( repo[:project_files], "github" )
      repo['task_status'] = task_status
      repo
    end

end
