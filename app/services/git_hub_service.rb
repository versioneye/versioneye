require 'benchmark'
require 'dalli'

class GitHubService

  A_TASK_NIL     = nil
  A_TASK_RUNNING = 'running'
  A_TASK_DONE    = 'done'


  def self.update_all_repos
    User.all(:timeout => true).live_users.where(:github_scope => 'repo').each do |user|
      update_repos_for_user user
    end
  end

  def self.update_repos_for_user user
    Rails.logger.debug "Importing repos for #{user.fullname}."
    user.github_repos.delete_all
    GitHubService.cached_user_repos user
    Rails.logger.debug  "Got #{user.github_repos.count} repos for #{user.fullname}."
    user.github_repos.all
  rescue => e
    Rails.logger.error "Cant import repos for #{user.fullname} \n #{e}"
  end


=begin
  Returns github repos for user;
  If user don't have yet any github repos
     or there's been any change on user's github account,
  then trys to read from github
  else it returns cached results from GitHubRepos collection.
  NB! allows only one running task per user;
=end
  def self.cached_user_repos user
    memcache      = memcache_client
    user_task_key = "#{user[:username]}-#{user[:github_id]}"
    task_status   = memcache.get user_task_key

    if task_status == A_TASK_RUNNING
      Rails.logger.debug "We are still importing repos for `#{user[:fullname]}.`"
      return task_status
    end

    if user[:github_token] and user.github_repos.all.count == 0
      Rails.logger.info 'Fetch Repositories from GitHub and cache them in DB.'
      n_repos    = Github.count_user_repos user
      if n_repos == 0
        Rails.logger.debug 'user has no repositories;'
        task_status = A_TASK_DONE
        memcache.set(user_task_key, task_status)
        return task_status
      end
      task_status = A_TASK_RUNNING
      memcache.set(user_task_key, task_status)
      Thread.new do
        orga_names = Github.orga_names(user.github_token)
        self.cache_user_all_repos(user, orga_names)
        memcache.set(user_task_key, A_TASK_DONE)
      end

    else
      Rails.logger.info 'Nothing is changed - skipping update.'
      task_status = A_TASK_DONE
    end

    task_status
  end


  def self.update_repo_info user, repo_fullname
    current_repo = GithubRepo.by_user(user).by_fullname(repo_fullname).shift
    if current_repo.nil?
      Rails.logger.error "User #{user[:username]} has no such repo `#{repo_fullname}`."
      return nil
    end

    repo_info = Github.repo_info repo_fullname, user[:github_token]
    repo_info = Github.read_repo_data repo_info, user[:github_token]
    updated_repo = GithubRepo.build_new(user, repo_info)
    current_repo.update_attributes(updated_repo.attributes)
    current_repo
  end


  private


    def self.memcache_client
      Dalli::Client.new(
        'localhost:11211',
        {
          :namespace  => 'github_app',
          :compress   => true,
          :expires_in => 30.minutes # Only allows import after X min; unless task unlocks!
        }
      )
    end


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
