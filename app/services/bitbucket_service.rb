require 'benchmark'
require 'dalli'

class BitbucketService

  A_TASK_NIL = nil
  A_TASK_RUNNING = 'running'
  A_TASK_DONE = 'done'
  A_MAX_WORKERS = 16


  def self.update_repo_info(user, repo_fullname)
    current_repo = user.bitbucket_repos.where(fullname: repo_fullname).shift
    if current_repo.nil?
      Rails.logger.error "User #{user[:username]} has no such repo `#{repo_fullname}`"
      return nil
    end

    repo_info = Bitbucket.repo_info repo_fullname, user[:bitbucket_token], user[:bitbucket_secret]
    repo_branches = Bitbucket.repo_branches repo_fullname, user[:bitbucket_token], user[:bitbucket_secret]
    repo_files = Bitbucket.repo_project_files repo_fullname, user[:bitbucket_token], user[:bitbucket_secret]

    updated_repo = BitbucketRepo.build_new(user, repo_info, repo_branches, repo_files)
    current_repo.update_attributes(updated_repo.attributes)
    current_repo
  end


  def self.cached_user_repos user
    memcache = memcache_client
    user_task_key = "#{user[:username]}-bitbucket"
    task_status = memcache.get(user_task_key)

    if task_status == A_TASK_RUNNING
      Rails.logger.debug "Still importing data for #{user[:username]} from bitbucket"
      return task_status
    end

    if user[:bitbucket_token] and user.bitbucket_repos.all.count == 0
      Rails.logger.info "Going to import bitbucket data for #{user[:username]}"
      task_status =  A_TASK_RUNNING
      memcache.set(user_task_key, task_status)
      Thread.new do
        cache_user_all_repos(user)
        memcache.set(user_task_key, A_TASK_DONE)
      end
    else
      Rails.logger.info "Nothing to import - maybe clean user's repo?"
      task_status = A_TASK_DONE
    end

    task_status
  end


  def self.cache_user_all_repos(user)
    puts "Going to cache users repositories."
    #load data
    user_orgs = Bitbucket.user_orgs(user)
    threads = []
    threads << Thread.new {self.cache_repos(user, user[:bitbucket_id])}
    user_orgs.each do |org|
      threads << Thread.new { self.cache_repos(user, org) }
    end
    threads.each { |worker| worker.join }

    #import missing invited repos
    cache_invited_repos(user)
  end

  def self.cache_repos(user, owner_name)
    token = user[:bitbucket_token]
    secret = user[:bitbucket_secret]
    repos = Bitbucket.read_repos(owner_name, token, secret)

    tasks = []
    #add information about branches and project files
    repos.each do |repo|
      tasks << Thread.new {add_repo(user, repo, token, secret)}
    end

    #simple workpool
    while not tasks.empty?
      workers = tasks.shift(A_MAX_WORKERS)
      workers.each {|task| task.join}
    end
    return true
  end

  def self.cache_invited_repos(user)
    token = user[:bitbucket_token]
    secret = user[:bitbucket_secret]
    repos = Bitbucket.read_repos_v1(token, secret)
    if repos.nil? or repos.empty?
      Rails.logger.error "cache_invited_repos | didnt get any repos from APIv1."
      return false
    end
    user.reload #pull newest updates
    existing_repo_fullnames  = Set.new user.bitbucket_repos.map(&:fullname)
    missing_repos = repos.keep_if {|repo| existing_repo_fullnames.include?(repo[:full_name]) == false}
    #add missing repos
    missing_repos.each do |old_repo|
      repo = Bitbucket.repo_info(old_repo[:full_name], token, secret) #fetch repo info from api2
      if repo.nil?
        Rails.logger.error "cache_invited_repos | didnt get repo info for `#{old_repo[:full_name]}`"
        next
      end
      add_repo(user, repo, token, secret)
    end
    return true
  end

  def self.add_repo(user, repo, token, secret)
    repo_name = repo[:full_name]
    read_branches = Thread.new do
      Thread.current[:val] = Bitbucket.repo_branches(repo_name, token, secret)
    end
    read_files = Thread.new do
      Thread.current[:val] = Bitbucket.repo_project_files(repo_name, token, secret)
    end
    bm = Benchmark.measure {read_branches.join; read_files.join; }
    Rails.logger.info("#-- Added #{repo_name}\n#{bm}\n")
    repo = BitbucketRepo.create_new(user, repo, read_branches[:val], read_files[:val])
    repo
  end


  private


    def self.memcache_client
      Dalli::Client.new(
        'localhost:11211',
        {
          :namespace  => 'github_app',
          :compress   => true,
          :expires_in => 10.minutes # Only allows import after X min; unless task unlocks!
        }
      )
    end

end
