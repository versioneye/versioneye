class Github

  include HTTParty
  persistent_connection_adapter

  A_USER_AGENT = "www.versioneye.com"
  A_API_URL    = "https://api.github.com"

  def self.api_url 
    A_API_URL
  end

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

  def self.user( token )
    return nil if token.to_s.empty?
    url           = "#{A_API_URL}/user?access_token=#{URI.escape( token )}"
    response_body = HTTParty.get(url, :headers => {"User-Agent" => A_USER_AGENT } ).response.body
    json_user     = JSON.parse response_body
    catch_github_exception json_user
  end

  def self.oauth_scopes( token )
    resp = HTTParty.get("https://api.github.com/user?access_token=#{token}", :headers => {"User-Agent" => A_USER_AGENT } )
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
    url = "#{A_API_URL}/user?access_token=#{URI.escape(user.github_token)}"
    response = self.head(url, headers: headers)
    response.code != 304
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
    request_headers = {"User-Agent" => A_USER_AGENT}
    response        = self.get(url, headers: request_headers)
    data            = catch_github_exception JSON.parse(response.body)
    data            = [] if data.nil?
    data.each do |repo|
      next if repo.nil? or repo['full_name'].to_s.empty?
      branch_docs = Github.repo_branches(user, repo['full_name'])
      if branch_docs and !branch_docs.nil?
        branches = branch_docs.map {|x| x['name']}
        repo['branches'] = branches
      else
        repo['branches'] = ["master"]
      end
    end

    paging_links = parse_paging_links(response.headers)
    repos = {
      repos: data,
      paging: {
        start: page,
        per_page: per_page
      },
      etag: response.headers["etag"],
      ratelimit: {
        limit: response.headers["x-ratelimit-limit"],
        remaining: response.header["x-ratelimit-remaining"]
      }
    }
    repos[:paging].merge! paging_links unless paging_links.nil?
    repos
  end

  def self.repo_branches(user, repo_name)
    request_headers = {"User-Agent" => A_USER_AGENT}
    url = "#{A_API_URL}/repos/#{repo_name}/branches?access_token=#{user.github_token}"
    response = self.get(url, headers: request_headers)
    catch_github_exception JSON.parse(response.body)
  end

  def self.repo_branch_info(user, repo_name, branch = "master")
    request_headers = {"User-Agent" => A_USER_AGENT}
    url = "#{A_API_URL}/repos/#{repo_name}/branches/#{branch}?access_token=#{user.github_token}"
    response = self.get(url, headers: request_headers)
    catch_github_exception JSON.parse(response.body)
  end

  def self.project_file_from_branch(user, repo_name, branch = "master")
    branch_info = Github.repo_branch_info user, repo_name, branch
    if branch_info.nil?
      Rails.logger.error "Cancelling importing: can't read branch info."
      return nil
    end

    project_file_info = Github.project_file_info( repo_name, branch_info["commit"]["sha"], user.github_token )
    if project_file_info.nil? || project_file_info.empty?
      Rails.logger.error "Cancelling importing: can't read info about project's file."
      return nil
    end


    project_file         = Github.fetch_file project_file_info["url"], user.github_token
    project_file["name"] = project_file_info["name"]
    project_file["type"] = project_file_info["type"]
    project_file
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    nil
  end

  # TODO: add tests
  def self.project_file_info(git_project, sha, token)
    result = Hash.new
    url    = "https://api.github.com/repos/#{git_project}/git/trees/#{sha}?access_token=" + URI.escape(token)
    tree   = JSON.parse HTTParty.get( url, :headers => {"User-Agent" => A_USER_AGENT} ).response.body
    tree['tree'].each do |file|
      name           = file['path']
      result['url']  = file['url']
      result['name'] = name
      type           = ProjectService.type_by_filename( name )
      if type
        result['type'] = type
        return result
      end
    end
    return Hash.new
  end

  def self.fetch_file( url, token )
    return nil if url.nil? || url.empty?
    response = HTTParty.get( "#{url}?access_token=" + URI.escape(token), :headers => {"User-Agent" => A_USER_AGENT} )
    if response.code != 200
      Rails.logger.error "Can't fetch file from #{url}:  #{response.code}\n
        #{response.message}\n#{response.data}"
      return nil
    end
    JSON.parse response.body
  end

  def self.fetch_raw_file( url, token )
    return nil if url.nil? || url.empty?
    response = HTTParty.get( "#{url}?access_token=" + URI.escape(token), 
                            :headers => {"User-Agent" => A_USER_AGENT,
                                         "Accept" => "application/vnd.github.VERSION.raw"} )
    if response.code != 200
      Rails.logger.error "Cant fetch file from #{url}:  #{response.code}\n
        #{response.message}\n#{response}"
      return nil
    end
    response.body
  end

  def self.orga_names( github_token )
    body = HTTParty.get("#{A_API_URL}/user/orgs?access_token=#{github_token}",
                        :headers => {"User-Agent" => A_USER_AGENT} ).response.body
    organisations = catch_github_exception JSON.parse( body )
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
    body = HTTParty.get("#{A_API_URL}/repos/#{name}?access_token=#{github_token}",
                        :headers => {"User-Agent" => A_USER_AGENT} ).response.body
    repo = catch_github_exception JSON.parse(body)
    return repo['private'] unless repo.nil? and !repo.is_a(Hash)
    false
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    return false
  end

  def self.repo_sha(repository, token)
    heads = JSON.parse HTTParty.get("#{A_API_URL}/repos/#{repository}/git/refs/heads?access_token=" + URI.escape(token),
                                    :headers => {"User-Agent" => A_USER_AGENT}  ).response.body
    heads.each do |head|
      return head['object']['sha'] if head['url'].match(/heads\/master$/)
    end
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
    body = HTTParty.get(
      "#{A_API_URL}/search/repositories?q=#{search_term}&#{pagination_data}",
      headers: {
        "User-Agent" => "A_USER_AGENT",
        "Accept" => "application/vnd.github.preview"
      }
    ).response.body

    JSON.parse(body)
  end

  def self.supported_languages()
    Set['java', 'ruby', 'python', 'node.js', 'php', 'javascript', 'coffeescript', 'clojure']
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
      return nil unless headers.has_key? "link"
      links = []
      headers["link"].split(",").each do |link_token|
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
