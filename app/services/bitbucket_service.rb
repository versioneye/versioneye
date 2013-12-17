require 'benchmark'
require 'dalli'

class BitbucketService
  A_TASK_NIL = nil
  A_TASK_RUNNING = 'running'
  A_TASK_DONE = 'done'

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
        self.cache_user_all_repos(user)
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
    threads << Thread.new {self.cache_repos(user, user[:bitbucket_id], 'user')}
    user_orgs.each do |org|
      threads << Thread.new { self.cache_repos(user, org, 'team') }
    end

    threads.each { |worker| worker.join }
  end

  #TODO: refactor as multi-threaded
  def self.cache_repos(user, owner_name, owner_type)
    token = user[:bitbucket_token]
    secret = user[:bitbucket_secret]
    owner_info = Bitbucket.user_info(owner_name, token, secret)
    p owner_info
    repos = Bitbucket.read_repos(owner_name, token, secret)
        
    #add information about branches and project files
    repos.each do |repo|
      bm = Benchmark.measure do
        branches = Bitbucket.repo_branches(repo[:full_name], token, secret)
        project_files = Bitbucket.repo_project_files(repo[:full_name], token, secret)
        BitbucketRepo.create_new(user, repo, owner_type, branches, project_files)
      end
      p "#-- Added #{repo[:full_name]}", bm
    end
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
