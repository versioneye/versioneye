require 'grape'
require 'entities_v2'

require_relative 'helpers/session_helpers'
require_relative 'helpers/paging_helpers'
require_relative 'helpers/product_helpers'

module V2
  class GithubApiV2 < Grape::API
    
    helpers SessionHelpers
    helpers PagingHelpers
    helpers ProductHelpers

    resource :github do 
      before do
        track_apikey
      end

      #TODO: add paging
      #TODO: add filters
      #-- GET '/' -------------------------------------------------------------
      desc "lists your's github repos",
            {
              notes: %q[text]
            }
      params do
        optional :page, type: String, desc: "The page number for a pagination."
        optional :org, type: String, desc: "Filter repositories by organization"
        optional :page, type: String, default: "1", desc: "Number of page"
        optional :organization, type: String, desc: "TODO:"
      end
      get '/' do
        authorized?
        user = current_user
        if !user.github_account_connected?
          error! "Github account is not connected. Check your settings on versioneye.com", 401
        end

        if user.github_repos.all.count == 0
          repos = GitHubService.cached_user_repos(user)
        else
          repos = user.github_repos.all
        end
        
        repos.each do |repo|
          repo[:repo_key] = repo[:fullname].to_s.gsub("/", ":").gsub(".", "~")
        end

        present repos, with: EntitiesV2::RepoEntity
      end


      #-- GET '/:repo_key' ----------------------------------------------------
      desc "shows the detailed information of repository", {
        notes: %q[TODO: add me]
      }
      params do
        requires :repo_key, type: String, desc: "encoded repo name with optional branch info."
      end
      get '/:repo_key' do
        authorized?
        user = current_user
        repo_fullname = decode_prod_key(params[:repo_key])

        repo = user.github_repos.by_fullname(repo_fullname).first
        repo_projects = Project.by_user(user).by_github(repo_fullname).to_a       
        unless repo 
          repo = {}
        end
        present :repo, repo, with: EntitiesV2::RepoEntity
        present :imported_projects, repo_projects, with: EntitiesV2::ProjectEntity
      end

      #-- POST '/:repo_key' --------------------------------------------------
      desc "imports project file from github", {
        notes: %q[TODO: add me]
      }
      params do
        requires :repo_key, type: String, desc: "encoded repo name with optional branch info"
        optional :branch, type: String, default: "master", desc: "the name of branch"
      end
      post '/:repo_key' do
        authorized?
        user = current_user
        repo_name = decode_prod_key(params[:repo_key])
        branch = params[:branch]

        repo = user.github_repos.by_fullname(repo_name).first
        ProjectService.import_from_github(user, repo_name, branch)
        project = Project.by_user(current_user).by_github(repo_name).where(github_branch: branch).first

        present :repo, repo, with: EntitiesV2::RepoEntity
        present :project, project, with: EntitiesV2::ProjectEntity
      end

      #-- DELETE '/:repo_key' -------------------------------------------------
      desc "remove imported project", {
        notes: %q[TODO: add me]
      }
      params do
        requires :repo_key, type: String, desc: "encoded repo-key with optional brnach info"
        optional :branch, type: String, default: "master", desc: "to specify branch"
      end
      delete '/:repo_key' do
        authorized?
        user = current_user
        repo_name = decode_prod_key(params[:repo_key])
        branch = params[:branch]

        project = Project.by_user(user).by_github(repo_name).where(github_branch: branch).shift
        error!("Project doesnt exists", 400) if project.nil?
        ProjectService.destroy project[:_id].to_s
        present :success, true
      end

      #TODO: add sync to update data
      #TODO: add update (delete+import)
      #todo: search on github
    end #end of resource block
  end
end

