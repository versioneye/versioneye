require 'grape'
require 'entities_v2'

require_relative 'helpers/session_helpers'
require_relative 'helpers/paging_helpers'

module V2
  class GithubApiV2 < Grape::API
    
    helpers SessionHelpers
    helpers PagingHelpers

    resource :github do 
      before do
        track_apikey
      end

      #-- GET '/' -------------------------------------------------------------
      desc "lists your's github repos",
            {
              notes: %q[text]
            }
      params do
        optional :page, type: String, desc: "The page number for a pagination."
        optional :org, type: String, desc: "Filter repositories by organization"
      end

      get '/' do
        authorized?
        user = current_user
        if !user.github_account_connected?
          error! "Github account is not connected. Check your settings on versioneye.com", 401
        end

        if user.github_repos.all.count == 0
          repos = GithubService.cached_user_repos(user)
        else
          repos = user.github_repos.all
        end
        
        repos.each do |repo|
          repo[:repo_key] = repo[:fullname].to_s.gsub("/", ":").gsub(".", "~")
        end

        present repos, with: EntitiesV2::RepoEntity
      end


      #-- GET '/:repo_key' ----------------------------------------------------
      desc "shows the detailed information of repository",
        {
          notes: %q[comment]
        }
      params do
        requires :repo_key, type: String, desc: "decoded repo name with optional branch info."
      end
      get '/:repo_key' do
        authorized?
        user = current_user
        
        repo_fullname = params[:repo_key].to_s.gsub(":", "/").gsub("~", ".")
        repo = user.github_repos.by_fullname(repo_fullname).first
        repo_projects = Project.by_user(user).by_github(repo_fullname)       
        
        p repo.to_json, repo_projects.to_json
        unless repo 
          repo = {}
        end
        #TODO: fixit
        response_data = { github: repo, projects: repo_projects }
        present response_data, with: EntitiesV2::RepoProjectEntity

      end

      #-- GET '/:'
    end
  end
end

