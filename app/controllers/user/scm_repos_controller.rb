class User::ScmReposController < ApplicationController


  def init
    render 'init', layout: 'application'
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


  private


    def remove_repo(project_id)
      project = Project.by_user( current_user ).by_id( project_id ).first
      if project.nil?
        raise "Can't remove project with id: `#{project_id}` - it does not exist. Please refresh the page."
      end

      ProjectService.destroy project_id
    end


end
