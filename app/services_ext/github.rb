require 'uri'
require 'excon'

class Github
  A_USER_AGENT = "www.versioneye.com"
  A_API_URL    = "https://api.github.com"
  A_DEFAULT_HEADERS = {
    "User-Agent" => A_USER_AGENT,
    "Connection" => "Keep-Alive"
  }
  @@conn = Excon.new(A_API_URL)

  def self.token( code )
    domain    = 'https://github.com/'
    uri       = 'login/oauth/access_token'
    query     = token_query( code )
    link      = "#{domain}#{uri}?#{query}"
    doc       = Nokogiri::HTML( open( URI.encode(link) ) )
    p_element = doc.xpath('//body/p')
    p_string  = p_element.text
    pips      = p_string.split("&")
    token     = pips[0].split("=")[1]
    token
  end

  def self.user(token)
    return nil if token.to_s.empty?
    path           = "/user?access_token=" + URI.escape( token )
    response      =  @@conn.get(path: path, :headers => A_DEFAULT_HEADERS )
    json_user     = JSON.parse response.body
    catch_github_exception json_user
  end

  def self.oauth_scopes( token )
    resp = @@conn.get(path: "/user?access_token=#{token}", headers: A_DEFAULT_HEADERS)
    resp.headers['x-oauth-scopes']
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    "no_scope"
  end

  def self.user_repos_changed?( user )
    repo = user.github_repos.all.first
    #if user don't have any repos in cache, then force to load data
    return true if repo.nil?
    headers = {
      "User-Agent" => A_USER_AGENT,
      "If-Modified-Since" => repo[:cached_at].httpdate
    }
    path = "/user?access_token=#{URI.escape(user.github_token)}"
    response = @@conn.head(path: path, headers: headers)
    response.status != 304
  end

  def self.user_repos(user, url = nil, page = 1, per_page = 30)
    url = "#{A_API_URL}/user/repos?page=#{page}&per_page=#{per_page}&access_token=#{user.github_token}" if url.nil?
    read_repos(user, url, page, per_page)
  end

  def self.user_orga_repos(user, orga_name, url = nil, page = 1, per_page = 30)
    url = "#{A_API_URL}/orgs/#{orga_name}/repos?access_token=#{user.github_token}" if url.nil?
    read_repos(user, url, page, per_page)
  end

  def self.read_repos(user, url, page = 1, per_page = 30)
    response        = Excon.get(url, headers: A_DEFAULT_HEADERS)
    data            = catch_github_exception JSON.parse(response.body)
    data            = [] if data.nil?
    data.each do |repo|
      next if repo.nil? or repo['full_name'].to_s.empty?
      time = Benchmark.measure do
        branch_docs = self.repo_branches(user, repo['full_name'])
        if branch_docs and !branch_docs.nil?
          branches = branch_docs.map {|x| x['name']}
          repo['branches'] = branches
        else
          repo['branches'] = ["master"]
        end
        #adds project files
        repo['project_files'] = repo_project_files(user, repo['full_name'])
      end
      puts "Reading `#{repo['full_name']}` took: #{time} "
    end

    paging_links = parse_paging_links(response.headers)
    repos = {
      repos: data,
      paging: {
        start: page,
        per_page: per_page
      },
      etag: response.headers["ETag"],
      ratelimit: {
        limit: response.headers["X-RateLimit-Limit"],
        remaining: response.headers["X-RateLimit-Remaining"]
      }
    }
    repos[:paging].merge! paging_links unless paging_links.nil?
    repos
  end

  def self.repo_branches(user, repo_name)
    path = "/repos/#{repo_name}/branches?access_token=#{user.github_token}"
    response = @@conn.get(path: path, headers: A_DEFAULT_HEADERS)
    catch_github_exception JSON.parse(response.body)
  end

  def self.repo_branch_info(user, repo_name, branch = "master")
    path= "/repos/#{repo_name}/branches/#{branch}?access_token=#{user.github_token}"
    response = @@conn.get(path: path, headers: A_DEFAULT_HEADERS)
    catch_github_exception JSON.parse(response.body)
  end

  def self.project_file_from_branch(user, repo_name, filename, branch = "master")
    branch_info = Github.repo_branch_info user, repo_name, branch
    if branch_info.nil?
      Rails.logger.error "Cancelling importing: can't read branch info."
      return nil
    end

    project_file_info = Github.project_file_info( repo_name, filename, branch_info["commit"]["sha"], user.github_token )
    if project_file_info.nil? || project_file_info.empty?
      Rails.logger.error "Cancelling importing: can't read info about project's file."
      return nil
    end
    project_file = fetch_project_from_url(user, project_file_info)
    project_file["name"] = project_file_info["name"]
    project_file["type"] = project_file_info["type"]
    project_file["branch"] = project_file_info["branch"]
    project_file
  end


  def self.fetch_project_file_directly(user, filename, branch, url)
    project_file = fetch_project_from_url(user, url)
    project_file["name"] = filename
    project_file["type"] = ProjectService.type_by_filename(filename)
    project_file["branch"] = branch
    project_file
  end

  def self.fetch_project_from_url(user, url)
    Github.fetch_file url, user.github_token
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    nil
  end

  # TODO: add tests
  def self.project_file_info(git_project, filename, sha, token)
    result = Hash.new
    path   = "/repos/#{git_project}/git/trees/#{sha}?access_token=" + URI.escape(token)
    response = @@conn.get(path, :headers => A_DEFAULT_HEADERS)
    tree   = JSON.parse response.body
    tree['tree'].each do |file|
      name           = file['path']
      result['url']  = file['url']
      result['name'] = name
      type           = ProjectService.type_by_filename( name )
      if filename == result['name']
        result['type'] = type
        return result
      end
    end
    result
  end

  def self.repo_branch_tree(user, repo_name, branch = "master", recursive = false)
    branches = repo_branches(user, repo_name)
    if branches.nil?
      Rails.logger.error "Can't read branches for `#{repo_name}`."
      return
    end

    branch_shas = Hash[branches.to_a.map {|x| [x['name'], x['commit']['sha']]}]
    unless branch_shas.has_key?(branch)
      msg = "Repo `#{repo_name}` doesnt have branch `#{branch}`: #{branch_shas.keys}"
      Rails.logger.error msg
      return
    end

    rec_val = (recursive == true) ? 1 : 0
    path = "/repos/#{repo_name}/git/trees/#{branch_shas[branch]}?access_token=#{user.github_token}&recursive=#{rec_val}"
    response = @@conn.get(path: path, headers: A_DEFAULT_HEADERS )
    if response.status != 200
      msg = "Can't fetch repo tree for `#{repo_name}` from #{url}:  #{response.code}\n#{response.message}\n#{response.body}"
      Rails.logger.error msg
      return nil
    end
    JSON.parse response.body
  end


  def self.project_files_from_branch(user, repo_name, branch = "master")
    tree = repo_branch_tree(user, repo_name, branch)
    if tree.nil? or !tree.has_key?('tree')
      msg = "Can't read tree for repo `#{repo_name}` on branch `#{branch}`"
      p msg
      Rails.logger.error msg
      return
    end

    tree['tree'].keep_if {|file| ProjectService.type_by_filename(file['path'].to_s) != nil}
  end

  #returns all project files in the given repos grouped by branches
  def self.repo_project_files(user, repo_name)
    branches = repo_branches(user, repo_name)
    if branches.nil? or branches.empty?
      msg = "#{repo_name} doesnt have any branches."
      Rails.logger.error(msg) and return
    end
    project_files = {}
    branches.each do |branch|
      branch_name = branch['name']
      branch_key = encode_db_key(branch_name)
      branch_files = project_files_from_branch(user, repo_name, branch_name)
      project_files[branch_key] = branch_files unless branch_files.nil?
    end

    project_files
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    return
  end

  def self.fetch_file( url, token )
    return nil if url.nil? || url.empty?
    response = Excon.get( "#{url}?access_token=" + URI.escape(token), :headers => A_DEFAULT_HEADERS )
    if response.code != 200
      Rails.logger.error "Can't fetch file from #{url}:  #{response.code}\n#{response.message}"
      return nil
    end
    JSON.parse response.body
  end

  def self.orga_names( github_token )
    path = "/user/orgs?access_token=#{github_token}"
    response = @@conn.get(path: path, :headers => A_DEFAULT_HEADERS )
    organisations = catch_github_exception JSON.parse( response.body )
    names = Array.new
    if organisations.nil? || organisations.empty?
      return names
    end
    organisations.each do |organisation|
      names << organisation['login']
    end
    names
  end

  def self.private_repo?( github_token, name )
    path = "/repos/#{name}?access_token=#{github_token}"
    response = @@conn.get(path: path, :headers => A_DEFAULT_HEADERS )
    repo = catch_github_exception JSON.parse(response.body)
    return repo['private'] unless repo.nil? and !repo.is_a(Hash)
    false
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    return false
  end

  def self.repo_sha(repository, token)
    path = "/repos/#{repository}/git/refs/heads?access_token=" + URI.escape(token)
    response = @@conn.get(path: path, :headers => A_DEFAULT_HEADERS)
    heads = JSON.parse response.body
    heads.each do |head|
      return head['object']['sha'] if head['url'].match(/heads\/master$/)
    end
    nil
  end

  def self.check_user_ratelimit(user)
    path = "/rate_limit?access_token=#{user.github_token}"
    response = @@conn.get(path: path, :headers => A_DEFAULT_HEADERS)
    response = JSON.parse response.body
    response['resources']
  rescue => e
    p e.message
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    return nil
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
    response = @@conn.get(
      "/search/repositories?q=#{search_term}&#{pagination_data}",
      headers: {
        "User-Agent" => "#{A_USER_AGENT}",
        "Accept" => "application/vnd.github.preview"
      }
    )
    JSON.parse(response.body)
  end

  def self.supported_languages
    Set['java', 'ruby', 'python', 'node.js', 'php', 'javascript', 'coffeescript', 'clojure']
  end

  def self.support_project_files
    Set['pom.xml', 'Gemfile', 'Gemfile.lock', 'composer.json', 'composer.lock', 'requirements.txt',
        'setup.py', 'package.json','bower.json', 'dependency.gradle', 'project.clj']
  end

  def self.encode_db_key(key_val)
    URI.escape(key_val, /\.|\$/)
  end
  def self.decode_db_key(key_val)
    URI.unescape key_val
  end

  private
    def self.language_supported?(lang)
      return false if lang.nil?
      lang.casecmp('Java')         == 0 ||
      lang.casecmp('Ruby')         == 0 ||
      lang.casecmp('Python')       == 0 ||
      lang.casecmp('Node.JS')      == 0 ||
      lang.casecmp("CoffeeScript") == 0 ||
      lang.casecmp("JavaScript")   == 0 ||
      lang.casecmp("PHP")          == 0 ||
      lang.casecmp("Clojure")      == 0
    end

=begin
  Method that checks does Github sent error message
  If yes, then it'll log it and return nil
  Otherwise it sends object itself
  Github responses for client errors:
  {"message": "Problems parsing JSON"}
=end
    def self.catch_github_exception(data)
      if data.is_a?(Hash) and data.has_key?('message')
        Rails.logger.error "Catched exception in response from Github API: #{data}"
        return nil
      else
        return data
      end
    rescue => e
      # by default here should be no message or nil
      # We expect that everything is ok and there is no error message
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.first
      nil
    end

    def self.parse_paging_links( headers )
      return nil unless headers.has_key? "Link"
      links = []
      headers["Link"].split(",").each do |link_token|
        matches = link_token.strip.match /<([\w|\/|\.|:|=|?|\&]+)>;\s+rel=\"(\w+)\"/m
        links << [matches[2], matches[1]]
      end
      Hash[*links.flatten]
    end

    def self.token_query( code )
      query = 'client_id='
      query += Settings.github_client_id
      query += '&client_secret='
      query += Settings.github_client_secret
      query += '&code=' + code
      query
    end

end
