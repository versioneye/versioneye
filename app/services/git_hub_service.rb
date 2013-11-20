require 'benchmark'
require 'dalli'

class GitHubService
  @@memcache_options = {
    :namespace => "github_app",
    :compress => true,
    :expires_in => 1.minute
  }
  @@memcache = Dalli::Client.new('localhost:11211', @@memcache_options)

  A_TASK_NIL = nil
  A_TASK_RUNNING = 'running'
  A_TASK_DONE = 'done'

  def self.update_all_repos
    User.all(:timeout => true).live_users.where(:github_scope => "repo").each do |user|
      update_repos_for_user user
    end
  end

  def self.update_repos_for_user( user )
    Rails.logger.debug "Importing repos for #{user.fullname}."
    user.github_repos.delete_all
    GitHubService.cached_user_repos user
    Rails.logger.debug  "Got #{user.github_repos.count} repos for #{user.fullname}."
    user.github_repos.all
  rescue => e
    Rails.logger.error "Cant import repos for #{user.fullname}\n#{e}"
  end

=begin
  Returns github repos for user;
  If user don't have yet any github repos
     or there's been any change on user's github account,
  then trys to read from github
  else it returns cached results from GitHubRepos collection.
  NB! allows only one running task per user;
=end
  def self.cached_user_repos( user )
    
    user_task_key = "#{user[:username]}-#{user[:github_id]}"

    task_status = @@memcache.get(user_task_key)

    if task_status == A_TASK_RUNNING
      Rails.logger.debug "We are still importing repos for `#{user[:fullname]}.`"
      return task_status
    end

    if user[:github_token] and user.github_repos.all.count == 0
      Rails.logger.info "Fetch Repositories from GitHub and cache them in DB."
      n_repos = Github.count_user_repos(user)
      if n_repos == 0 
        Rails.logger.debug "user had no repositories;"
        task_status = A_TASK_DONE
        @@memcache.set(user_task_key, task_status)
        return task_status
      end
      task_status = A_TASK_RUNNING
      @@memcache.set(user_task_key, task_status)
      Thread.new do
        orga_names = Github.orga_names(user.github_token)
        self.cache_user_all_repos(user, orga_names)
        task_status = A_TASK_DONE

        @@memcache.set(user_task_key, task_status)
      end
    elsif Github.user_repos_changed?( user )
      Rails.logger.info "Repos are changed - going to re-import all user repos."
      user.github_repos.delete_all
      self.cached_user_repos user
    else
      Rails.logger.info "Nothing is changed - skipping update."
      task_status = A_TASK_DONE
    end

    task_status
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
      puts "Going to cache users repositories."
      user_info = Github.user(user.github_token)
      user[:user_login] = user_info['login'] if user_info.is_a?(Hash)
      #load data
      threads = []
      threads << Thread.new {self.cache_user_repos(user)}
      orga_names.each do |orga_name|
        threads << Thread.new { self.cache_user_orga_repos(user, orga_name) }
      end

      threads.each { |worker| worker.join }
    end

    def self.cache_user_repos( user )
      url = nil
      begin
        data = Github.user_repos(user, url)
        url = data[:paging]["next"]
      end while not url.nil?
    end

    def self.cache_user_orga_repos(user, orga_name)
      url = nil
      begin
        data = Github.user_orga_repos(user, orga_name, url)
        url = data[:paging]["next"]
      end while not url.nil?
    end
end
