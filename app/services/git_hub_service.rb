class GitHubService

=begin
  Returns github repos for user;
  If user dont have yet any github repos
     or there's been any change on user's github account,
  then trys to read from github
  else it returns cached results from GitHubRepos collection.
=end
  def self.cached_user_repos( user )
    if user.github_repos.all.count == 0
      Rails.logger.info "Fetch Repositories from GitHub and cache them in DB."
      self.cache_user_repos( user )
    elsif Github.user_repos_changed?( user )
      Rails.logger.info "Repos are changed - going to re-import all user repos."
      user.github_repos.delete_all
      self.cached_user_repos user
    else
      Rails.logger.info "Nothing is changed - skipping update."
    end
    GithubRepo.by_user( user )
  end

  private

    def self.cache_user_repos( user )
      url = nil
      begin
        data = Github.user_repos(user, url)
        data[:repos].each do |repo|
          GithubRepo.add_new(user, repo, data[:etag])
        end
        url = data[:paging]["next"]
      end while not url.nil?
    end

end
