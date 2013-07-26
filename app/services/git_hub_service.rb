class GitHubService

=begin
  Returns github repos for user;
  If user don't have yet any github repos
     or there's been any change on user's github account,
  then trys to read from github
  else it returns cached results from GitHubRepos collection.
=end
  def self.cached_user_repos( user )
    if user.github_repos.all.count == 0
      Rails.logger.info "Fetch Repositories from GitHub and cache them in DB."
      orga_names = Github.orga_names(user.github_token)
      self.cache_user_all_repos(user, orga_names)
    elsif Github.user_repos_changed?( user )
      Rails.logger.info "Repos are changed - going to re-import all user repos."
      user.github_repos.delete_all
      self.cached_user_repos user
    else
      Rails.logger.info "Nothing is changed - skipping update."
    end
    GithubRepo.by_user( user )
  end

  def self.bad_credentail?(repo)
    if repo.is_a?(Hash) and repo.has_key?("message")
      Rails.logger.error("Catched Github API exception: #{repo}")
      return true
    end
    return false
  rescue => e
    Rails.logger.error "Bad Credentials"
    true
  end

  private

    def self.cache_user_all_repos(user, orga_names)
      user_info = Github.user(user.github_token)
      user[:user_login] = user_info['login'] if user_info.is_a?(Hash)
      #load data
      self.cache_user_repos(user)
      orga_names.each {|orga_name| self.cache_user_orga_repos(user, orga_name)}
    end

    def self.cache_user_repos( user )
      url = nil
      begin
        data = Github.user_repos(user, url)
        data[:repos].each do |repo|
          return nil if bad_credentail?( repo )
          begin
            GithubRepo.add_new(user, repo, data[:etag])
          rescue
            Rails.logger.error("Cant add repo to cache: #{repo}")
          end
        end
        url = data[:paging]["next"]
      end while not url.nil?
    end

    def self.cache_user_orga_repos(user, orga_name)
      url = nil
      begin
        data = Github.user_orga_repos(user, orga_name, url)
        data[:repos].each do |repo|
          return nil if bad_credentail?( repo )
          GithubRepo.add_new(user, repo, data[:etag])
        end
        url = data[:paging]["next"]
      end while not url.nil?
    end

end
