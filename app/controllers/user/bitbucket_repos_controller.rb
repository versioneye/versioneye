class User::BitbucketReposController < ApplicationController

  before_filter :authenticate

  def init
    render 'init', layout: 'application'
  end

  def index
    status_message = ''
    status_success = true
    task_status = ''

    if current_user.bitbucket_token.nil?
      status_message = 'Your VersionEye account is not connected to BitBucket.'
      status_success = false
      task_status = BitbucketService::A_TASK_DONE
    else
      task_status  = BitbucketService.cached_user_repos current_user
      user_repos = current_user.bitbucket_repos
      if user_repos && user_repos.count > 0
        user_repos = user_repos.desc(:commited_at)
      end

      if task_status == BitbucketService::A_TASK_DONE and user_repos.count == 0
        status_message = %w{
          We couldn't find any repositories in your BitBucket account.
          If you think that's an error contact the VersionEye team.
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
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    render text: "An error occured. We are not able to import BitBucket repositories. Please contact the VersionEye team.", status: 503
  end


  def show
    owner = params[:owner]
    repo  = params[:repo]
    fullname = "#{owner}/#{repo}"
    @repo = current_user.bitbucket_repos.by_fullname( fullname ).first
  end

  def repo_files
    task_status = ''
    owner = params[:owner]
    repo  = params[:repo]
    fullname = "#{owner}/#{repo}"
    repo = current_user.bitbucket_repos.by_fullname( fullname ).first

    task_status = BitbucketService.status_for current_user, repo

    processed_repo = process_repo( repo )

    render json: {
      task_status: task_status,
      repo: processed_repo
    }.to_json
  end


  def import
    id = params[:id]
    sps = id.split("::")
    repo_fullname = sps[0].gsub(":", "/")
    branch = sps[1].gsub(":", "/")
    path = sps[2].gsub(":", "/")
    repo = import_repo( repo_fullname, branch, path )
    if repo.is_a?(String)
      render text: repo, status: 405 and return
    end
    render json: repo
  rescue => e
    Rails.logger.error "failed to import: #{e.message}"
    render text: e.message, status: 503
  end


  def remove
    id = params[:id]
    result = remove_repo( id )
    render json: result
  rescue => e
    Rails.logger.error "failed to remove: #{e.message}"
    render text: e.message, status: 503
  end


  def clear
    results = BitbucketRepo.by_user( current_user ).delete_all
    flash[:success] = "Cache is cleaned. Ready to re-import."
    redirect_to :back
  end


  private

    def import_repo(project_name, branch, filename)
      err_message = 'Something went wrong. It was not possible to save the project. Please contact the VersionEye team.'

      project = ProjectImportService.import_from_bitbucket(current_user, project_name, filename, branch)

      raise err_message if project.nil?
      raise project if project.is_a? String

      repo = {
        repo: project_name,
        filename: filename,
        branch: branch,
        project_id: project.id,
        project_url: url_for(controller: 'projects', action: "show", id: project.id)
      }
      repo
    end


    def remove_repo(project_id)
      project = Project.by_user( current_user ).by_id( project_id ).first
      if project.nil?
        raise "Can't remove project with id: `#{project_id}` - it does not exist. Please refresh the page."
      end

      ProjectService.destroy project_id
    end


    def update_repo(command_data)
      Rails.logger.debug "Going to update repo-info for #{command_data}"
      repo = BitbucketService.update_repo_info(current_user, command_data["repoFullname"])
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
      imported_repos      = current_user.projects.by_source(Project::A_SOURCE_BITBUCKET)
      imported_repo_names = imported_repos.map(&:scm_fullname).to_set
      supported_langs     = Product::A_LANGS_SUPPORTED.map{ |lang| lang.downcase }
      repo[:supported] = supported_langs.include? repo[:language]
      repo[:imported_files] = []

      if imported_repo_names.include?(repo[:fullname])
        imported_files = imported_repos.where(scm_fullname: repo[:fullname])
        imported_files.each do |imported_project|
          filename = imported_project.filename
          project_info = {
            repo: repo[:fullname],
            branch: imported_project[:scm_branch],
            filename: filename,
            project_url: url_for(controller: 'projects', action: "show", id: imported_project.id),
            project_id:  imported_project.id,
            created_at: imported_project[:created_at]
          }
          repo[:imported_files] << project_info
        end
      end
      repo[:project_files] = decode_branch_names(repo[:project_files])
      repo[:task_status] = task_status
      repo
    end


    #function that decodes encoded branch-keys to plain string
    def decode_branch_names(project_files)
      return if project_files.nil?
      decoded_map = {}
      project_files.each_pair do |branch, files|
        decoded_branch = Bitbucket.decode_db_key(branch)
        decoded_map[decoded_branch] = files
      end
      decoded_map
    end
end
