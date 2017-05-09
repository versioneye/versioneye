class User::ScmReposController < ApplicationController

  before_action :load_orga, :only => [:index, :show, :import, :init]

  def init
    render 'init', layout: 'application'
  end


  def import
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    response.headers['Last-Modified'] = Time.now.httpdate

    id  = params[:id]
    sps = id.split("::")
    repo_fullname = sps[0].gsub(":", "/")
    branch = sps[1].gsub(":", "/")
    path   = sps[2].gsub(":", "/")
    repo   = import_repo( repo_fullname, branch, path )
    if repo.is_a?(String) && repo.match(/\Aerror_/)
      render plain: repo.to_s.gsub("error_", ""), status: 500
    elsif repo.is_a?(String)
      render plain: repo.to_s, status: 405
    else
      render json: repo
    end
  rescue => e
    logger.error "failed to import: #{e.message}"
    render plain: e.message, status: 503
  end


  private


    def load_orga
      orga_id = cookies.signed[:orga]
      return nil if orga_id.to_s.empty?

      @organisation = Organisation.find orga_id
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
