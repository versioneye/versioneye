#------------------------------------------------------------------------------
# Github - helper functions to manage Github's data.
#
# NB! For consistancy: every function that returns hash-map, should have
# symbolized keys. For that you can use 2 helpers function:
#
#  * {'a' => 1}.deep_symbolize_keys - encodes keys recursively
#
#  * JSON.parse(json_string, symbolize_names: true)
#
# If you're going to add simple get-request function, then use `get_json`.
# This function builds correct headers and handles Github exceptions.
#
#------------------------------------------------------------------------------

require 'uri'
require 'httparty'

class Github

  A_USER_AGENT = 'Chrome/28(www.versioneye.com, contact@versioneye.com)'
  A_API_URL    = 'https://api.github.com'
  A_WORKERS_COUNT = 4
  A_DEFAULT_HEADERS = {
    'Accept' => 'application/vnd.github.v3+json',
    'User-Agent' => A_USER_AGENT,
    'Connection' => 'Keep-Alive'
  }

  include HTTParty
  persistent_connection_adapter({
    name: 'versioneye_github_client',
    pool_size: 32,
    keep_alive: 30
  })

  def self.token code
    response = Octokit.exchange_code_for_token code, Settings.github_client_id, Settings.github_client_secret
    response.access_token
  end

  def self.user token
    client = user_client token
    JSON.parse client.user.to_json
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join( "\n" )
    nil
  end

  def self.oauth_scopes token
    client = user_client token
    client.scopes token
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    'no_scope'
  end

  def self.user_client token
    return nil if token.to_s.empty?
    Octokit::Client.new :access_token => token
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join "\n"
    nil
  end

  #returns how many repos user has. NB! doesnt count orgs
  def self.count_user_repos user
    n = 0
    return n if user[:github_token].nil?

    url = "#{A_API_URL}/user?access_token=#{user[:github_token]}"
    user_info = get_json(url, user[:github_token])
    if user_info
      n = user_info[:public_repos].to_i + user_info[:total_private_repos].to_i
    end
    n
  end

  def self.user_repos user, url = nil, page = 1, per_page = 30
    url = "#{A_API_URL}/user/repos?page=#{page}&per_page=#{per_page}&access_token=#{user.github_token}" if url.nil?
    read_repos(user, url, page, per_page)
  end

  def self.user_orga_repos user, orga_name, url = nil, page = 1, per_page = 30
    url = "#{A_API_URL}/orgs/#{orga_name}/repos?access_token=#{user.github_token}" if url.nil?
    read_repos(user, url, page, per_page)
  end

  def self.repo_info repo_fullname, token
    get_json "#{A_API_URL}/repos/#{repo_fullname}", token
  end

  def self.read_repo_data repo, token, try_n = 3
    return nil if repo.nil?
    project_files = nil
    repo = repo.deep_symbolize_keys
    fullname = repo[:full_name]
    branch_docs = self.repo_branches(fullname, token)
    if branch_docs and !branch_docs.nil?
      branches = branch_docs.map {|x| x[:name]}
      repo[:branches] = branches
    else
      repo[:branches] = ["master"]
    end

    #adds project files
    try_n.times do
      project_files = repo_project_files(fullname, token, branch_docs)
      break unless project_files.nil? or project_files.empty?
      p "Trying to read `#{fullname}` again"
      sleep 3
    end

    if project_files.nil?
      msg = "Cant read project files for repo `#{full_name}`. Tried to read #{try_n} ntimes."
      Rails.logger.error msg
    end

    repo[:project_files] = project_files
    repo
  end

  def self.execute_job workers
    workers.each {|worker| worker.join}
  end

  def self.read_repos user, url, page = 1, per_page = 30
    response        = get(url, headers: A_DEFAULT_HEADERS)
    data            = catch_github_exception JSON.parse(response.body, symbolize_names: true)
    data            = [] if data.nil?
    workers         = []
    repo_docs       = []
    data.each do |repo|
      next if repo.nil? or repo[:full_name].to_s.empty?

      workers << Thread.new do
        time = Benchmark.measure do
          repo_data = read_repo_data(repo, user.github_token)
          new_repo = GithubRepo.create_new(user, repo_data, "1")
          repo_docs << new_repo
        end
        puts "Reading `#{repo[:full_name]}` took: #{time}"
        sleep 1/100.0
      end
      execute_job(workers) if workers.count == A_WORKERS_COUNT
    end

    #execute & wait reduntant tasks
    execute_job(workers)
    paging_links = parse_paging_links(response.headers)
    repos = {
      repos: repo_docs,
      paging: {
        start: page,
        per_page: per_page
      },
      etag: response.headers["etag"],
      ratelimit: {
        limit: response.headers["x-ratelimit-limit"],
        remaining: response.headers["x-ratelimit-remaining"]
      }
    }
    repos[:paging].merge! paging_links unless paging_links.nil?
    repos
  end

  def self.repo_branches repo_name, token
    url = "#{A_API_URL}/repos/#{repo_name}/branches"
    get_json(url, token)
  end

  def self.repo_branch_info repo_name, branch = "master", token = nil
    url = "#{A_API_URL}/repos/#{repo_name}/branches/#{branch}"
    get_json(url, token)
  end

  def self.fetch_project_file_from_branch repo_name, filename, branch = "master", token = nil
    branch_info = Github.repo_branch_info repo_name, branch, token
    if branch_info.nil?
      Rails.logger.error "Cancelling importing: can't read branch info."
      return nil
    end

    file_info = Github.project_file_info( repo_name, filename, branch_info[:commit][:sha], token)
    if file_info.nil? || file_info.empty?
      Rails.logger.error "Cancelling importing: can't read info about project's file."
      return nil
    end
    project_file = fetch_file(file_info[:url], token)
    return nil if project_file.nil?

    project_file[:name] = file_info[:name]
    project_file[:type] = file_info[:type]
    project_file[:branch] = branch
    project_file
  end

  def self.fetch_project_file_directly(filename, branch, url, token)
    project_file = fetch_file(url, token)
    return nil if project_file.nil?

    project_file[:name] = filename
    project_file[:type] = ProjectService.type_by_filename(filename)
    project_file[:branch] = branch
    project_file
  end

  # TODO: add tests
  def self.project_file_info(git_project, filename, sha, token)
    result = Hash.new
    url   = "#{A_API_URL}/repos/#{git_project}/git/trees/#{sha}"
    tree = get_json(url, token)
    return if tree.nil? or not tree.has_key?(:tree)

    tree[:tree].each do |file|
      name           = file[:path]
      result[:url]  = file[:url]
      result[:name] = name
      type           = ProjectService.type_by_filename( name )
      if filename == result[:name]
        result[:type] = type
        return result
      end
    end
    result
  end

  #TODO: refactor to use get_json again ...
  def self.fetch_repo_branch_tree(repo_name, token, branch_sha, recursive = false)
    rec_val = recursive ? 1 : 0
    url = "#{A_API_URL}/repos/#{repo_name}/git/trees/#{branch_sha}?access_token=#{token}&recursive=#{rec_val}"
    response = get(url, headers: A_DEFAULT_HEADERS )
    if response.code != 200
      msg = "Can't fetch repo tree for `#{repo_name}` from #{url}: #{response.code} #{response.body}"
      Rails.logger.error msg
      return nil
    end
    JSON.parse(response.body, symbolize_names: true)
  end

  # TODO recursive param is never used. Refactor!
  def self.project_files_from_branch(repo_name, token, branch_sha, branch = "master", recursive = false, try_n = 3)
    branch_tree = nil

    try_n.times do
      branch_tree = fetch_repo_branch_tree(repo_name, token, branch_sha)
      break unless branch_tree.nil?
      Rails.logger.error "Going to read tree of branch `#{branch}` for #{repo_name} again after little pause."
      sleep 1 #it's required to prevent bombing Github's api after our request got rejected
    end

    if branch_tree.nil? or !branch_tree.has_key?(:tree)
      msg = "Can't read tree for repo `#{repo_name}` on branch `#{branch}`."
      Rails.logger.error msg
      return
    end

    project_files = branch_tree[:tree].keep_if {|file| ProjectService.type_by_filename(file[:path].to_s) != nil}
    project_files.each {|file| file[:uuid] = SecureRandom.hex}

    project_files
  end

  #returns all project files in the given repos grouped by branches
  def self.repo_project_files(repo_name, token, branch_docs = nil)

    branches = branch_docs ? branch_docs : repo_branches(repo_name, token)

    if branches.nil? or branches.empty?
      msg = "#{repo_name} doesnt have any branches."
      Rails.logger.error(msg) and return
    end

    project_files = {}
    branches.each do |branch|
      branch_name  = branch[:name]
      branch_key   = encode_db_key(branch_name)
      branch_sha   = branch[:commit][:sha]
      branch_files = project_files_from_branch(repo_name, token, branch_sha)
      project_files[branch_key] = branch_files unless branch_files.nil?
    end

    project_files
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  end

  def self.fetch_file( url, token )
    return nil if url.nil? || url.empty?
    response = get( "#{url}?access_token=" + URI.escape(token), :headers => A_DEFAULT_HEADERS )
    if response.code != 200
      Rails.logger.error "Can't fetch file from #{url}:  #{response.code}\n#{response.message}"
      return nil
    end
    JSON.parse response.body
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def self.orga_names( github_token )
    url = "#{A_API_URL}/user/orgs?access_token=#{github_token}"
    response = get(url, :headers => A_DEFAULT_HEADERS )
    organisations = catch_github_exception JSON.parse(response.body, symbolize_names: true )
    names = Array.new
    return names if organisations.nil? || organisations.empty?
    names = organisations.map {|x| x[:login]}
    names
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    []
  end

  def self.private_repo?( github_token, name )
    url = "#{A_API_URL}/repos/#{name}?access_token=#{github_token}"
    response = get(url, :headers => A_DEFAULT_HEADERS )
    repo = catch_github_exception JSON.parse(response.body)
    return repo['private'] unless repo.nil? and !repo.is_a?(Hash)
    false
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    return false
  end

  def self.repo_sha(repository, token)
    url = "#{A_API_URL}/repos/#{repository}/git/refs/heads?access_token=" + URI.escape(token)
    response = get(url, :headers => A_DEFAULT_HEADERS)
    heads = JSON.parse response.body

    heads.each do |head|
      return head['object']['sha'] if head['url'].match(/heads\/master$/)
    end
    nil
  end

  # TODO check if needed
  def self.check_user_ratelimit(user)
    url = "#{A_API_URL}/rate_limit?access_token=#{user.github_token}"
    response = get(url, :headers => A_DEFAULT_HEADERS)

    response = JSON.parse response.body
    response['resources']
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def self.search(q, langs = nil, users = nil, page = 1, per_page = 30)
    search_term = "#{q}"
    if langs
      langs.gsub!(/\s+/, '')
      search_term += "+language:#{langs}"
    end

    if users
      u = []
      tokens = users.split(",")
      tokens.each do |user|
        user.strip!
        user += "@#{user}" unless user =~ /@/
        u <<  user
      end
      search_term += " #{u.join(',')}"
    end

    search_term.gsub!(/\s+/, '+')
    pagination_data = "page=#{page}&per_page=#{per_page}"

    response = get(
      "#{A_API_URL}/search/repositories?q=#{search_term}&#{pagination_data}",
      headers: {
        "User-Agent" => "#{A_USER_AGENT}",
        "Accept" => "application/vnd.github.preview"
      }
    )
    JSON.parse(response.body)
  end

  def self.get_json(url, token = nil, raw = false)
    request_headers = A_DEFAULT_HEADERS
    if token
      request_headers["Authorization"] = "token #{token}"
    end
    response = get(url, headers: request_headers)
    return response if raw
    content = JSON.parse(response.body, symbolize_names: true)
    catch_github_exception(content)
  end

  def self.support_project_files
    Set['pom.xml', 'Gemfile', 'Gemfile.lock', 'composer.json', 'composer.lock', 'requirements.txt',
        'setup.py', 'package.json','bower.json', 'dependency.gradle', 'project.clj', 'Podfile', 'Podfile.lock']
  end

  def self.encode_db_key(key_val)
    URI.escape(key_val.to_s, /\.|\$/)
  end
  def self.decode_db_key(key_val)
    URI.unescape key_val.to_s
  end

  private

=begin
  Method that checks does Github sent error message
  If yes, then it'll log it and return nil
  Otherwise it sends object itself
  Github responses for client errors:
  {"message": "Problems parsing JSON"}
=end
    def self.catch_github_exception(data)
      if data.is_a?(Hash) and data.has_key?(:message)
        Rails.logger.error "Catched exception in response from Github API: #{data}"
        return nil
      else
        return data
      end
    rescue => e
      # by default here should be no message or nil
      # We expect that everything is ok and there is no error message
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      nil
    end

    def self.parse_paging_links( headers )
      return nil unless headers.has_key? "link"
      links = []
      headers["link"].split(",").each do |link_token|
        matches = link_token.strip.match /<([\w|\/|\.|:|=|?|\&]+)>;\s+rel=\"(\w+)\"/m
        links << [matches[2], matches[1]]
      end
      Hash[*links.flatten]
    end

end
