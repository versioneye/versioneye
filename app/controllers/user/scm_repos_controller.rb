class User::ScmReposController < ApplicationController


  def init
    render 'init', layout: 'application'
  end


  def import
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    response.headers['Last-Modified'] = Time.now.httpdate

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
    logger.error "failed to import: #{e.message}"
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


  private


    def remove_repo(project_id)
      project = Project.by_user( current_user ).by_id( project_id ).first
      if project.nil?
        raise "Can't remove project with id: `#{project_id}` - it does not exist. Please refresh the page."
      end
      clear_import_cache project
      ProjectService.destroy_by current_user, project_id
    end


    def create_project_info( repo, imported_project )
      filename = imported_project.filename
      project_info = {
          repo: repo[:fullname],
          branch: imported_project[:scm_branch],
          filename: filename,
          project_url: url_for(controller: 'projects', action: "show", id: imported_project.id),
          project_id:  imported_project.id,
          created_at: imported_project[:created_at]
        }
    end


    def decode_branch_names(project_files, scm = "github")
      return if project_files.nil?

      decoded_map = {}
      project_files.each_pair do |branch, files|
        decoded_branch = nil
        decoded_branch = Github.decode_db_key(branch)    if scm.eql? "github"
        decoded_branch = Bitbucket.decode_db_key(branch) if scm.eql? "bitbucket"
        decoded_branch = Stash.decode_db_key(branch)     if scm.eql? "stash"
        decoded_map[decoded_branch] = files
      end
      decoded_map
    end


end
