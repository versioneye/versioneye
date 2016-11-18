class User::StashReposController < User::ScmReposController

  before_filter :authenticate


  def index
    status_message = ''
    status_success = true
    task_status = ''

    if current_user.stash_token.nil?
      status_message = 'Your VersionEye account is not connected to Stash.'
      status_success = false
      task_status = StashService::A_TASK_DONE
    else
      task_status = StashService.cached_user_repos current_user
      user_repos = current_user.stash_repos
      if user_repos && user_repos.count > 0
        user_repos = user_repos.desc(:created_at)
      end

      if task_status == StashService::A_TASK_DONE and user_repos.count == 0
        status_message = %w{
          We couldn't find any repositories in your Stash account.
          If you think that's an error please contact the VersionEye team.
        }.join(' ')
        status_success = false
      end
    end

    render json: {
      success: status_success,
      task_status: task_status,
      repos: user_repos,
      message: status_message
    }.to_json
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    render text: "An error occured. We are not able to import Stash repositories. Please contact the VersionEye team.", status: 503
  end


  def show
    owner = params[:owner]
    repo  = params[:repo]
    fullname = "#{owner}/#{repo}"
    @repo = current_user.stash_repos.by_fullname( fullname ).first
  end


  def reimport
    owner = params[:owner]
    repo  = params[:repo]
    fullname = "#{owner}/#{repo}"
    repos = StashRepo.by_user( current_user ).by_fullname( fullname )
    repos.each do |repo|
      repo.branches = nil
      repo.project_files = nil
      repo.save
      clear_repo_cache repo
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
    repo = current_user.stash_repos.by_fullname( fullname ).first
    task_status = StashService.status_for current_user, repo
    processed_repo = process_repo( repo )

    render json: {
      task_status: task_status,
      repo: processed_repo
    }.to_json
  end


  def clear
    user = current_user
    results = StashRepo.by_user( current_user ).delete_all
    user_task_key = "#{user[:username]}-stash"
    StashService.cache.delete( user_task_key )
    flash[:success] = "Cache is cleaned. Ready to re-import."
    redirect_to :back
  end


  def remove
    id = params[:id]
    result = remove_repo( id )
    render json: result
  rescue => e
    Rails.logger.error "failed to remove: #{e.message}"
    render text: e.message, status: 503
  end


  private


    def remove_repo( project_id )
      stash_path = project_id.split("::")
      repo_fullname = stash_path[0].gsub(":", "/")
      branch        = stash_path[1].gsub(":", "/")
      path          = stash_path[2].gsub(":", "/")
      project = Project.where( :scm_fullname => repo_fullname, :scm_branch => branch, :s3_filename => path, :source => Project::A_SOURCE_STASH ).first
      if project.nil?
        raise "Can't remove project with id: `#{project_id}` - it does not exist. Please refresh the page."
      end
      if !project.is_collaborator?( current_user )
        raise "Can't remove project with id: `#{project_id}` - You are not a collaborator of the project!"
      end
      clear_import_cache project
      ProjectService.destroy project
    end


    def clear_repo_cache repo
      user  = current_user
      repo_task_key = "stash:::#{user.id.to_s}:::#{repo.id.to_s}"
      StashService.cache.delete( repo_task_key )
    rescue => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join "\n"
    end


    def clear_import_cache project
      key = "stash:::#{current_user.username}:::#{project.scm_fullname}:::#{project.filename}:::#{project.scm_branch}"
      ProjectService.cache.delete key
    end


    def import_repo(project_name, branch, filename)
      project_id = ''
      project_url = ''
      orga_id = nil
      orga_id = @organisation.ids if @organisation
      status = ProjectImportService.import_from_stash_async current_user, project_name, filename, branch, orga_id
      if status && status.match(/\Adone_/)
        project_id = status.gsub("done_", "")
        project = Project.find project_id
        project_url = url_for(controller: 'projects', action: "show", id: project.id)
        status = 'done'
      elsif status && status.match(/\Aerror_/)
        return status
      end

      {
        repo: project_name,
        filename: filename,
        branch: branch,
        status: status,
        project_id: project_id,
        project_url: project_url
      }
    end


=begin
  adds additional metadata for each item in repo collection,
  for example is this project already imported etc
=end
    def process_repo(repo, task_status = nil)
      imported_repos      = current_user.projects.by_source(Project::A_SOURCE_STASH)
      imported_repo_names = imported_repos.map(&:scm_fullname).to_set
      repo[:supported] = true
      repo[:imported_files] = []

      if imported_repo_names.include?(repo[:fullname])
        imported_files = imported_repos.where(scm_fullname: repo[:fullname])
        imported_files.each do |imported_project|
          filename = imported_project.filename
          project_info = create_project_info( repo, imported_project )
          repo[:imported_files] << project_info
        end
      end
      repo[:project_files] = decode_branch_names( repo[:project_files], "stash" )
      repo[:task_status] = task_status
      repo
    end


end
