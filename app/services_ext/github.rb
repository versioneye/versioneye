class Github
  include HTTParty
  persistent_connection_adapter

  A_USER_AGENT = "www.versioneye.com"
  A_API_URL = "https://api.github.com"

  def self.token( code )
    domain = 'https://github.com/'
    uri = 'login/oauth/access_token'
    query = 'client_id='
    query += Settings.github_client_id
    query += '&client_secret='
    query += Settings.github_client_secret
    query += '&code=' + code
    link = "#{domain}#{uri}?#{query}"
    doc = Nokogiri::HTML( open( URI.encode(link) ) )
    p_element = doc.xpath('//body/p')
    p_string = p_element.text
    pips = p_string.split("&")
    token = pips[0].split("=")[1]
    token
  end

  def self.user( token )
    url = 'https://api.github.com/user?access_token=' + URI.escape( token )
    response_body = HTTParty.get(url, :headers => {"User-Agent" => A_USER_AGENT } ).response.body
    json_user = JSON.parse response_body
    json_user
  end

  def self.oauth_scopes( token )
    resp = HTTParty.get("https://api.github.com/user?access_token=#{token}", :headers => {"User-Agent" => A_USER_AGENT } )
    resp.headers['x-oauth-scopes']
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    "no_scope"
  end

  def self.parse_paging_links(headers)
    return nil unless headers.has_key? "link"
    links = []
    headers["link"].split(",").each do |link_token|
      matches = link_token.strip.match /<([\w|\/|\.|:|=|?|\&]+)>;\s+rel=\"(\w+)\"/m
      links << [matches[2], matches[1]]
    end

    Hash[*links.flatten]
  end
 
  def self.user_repos_changed?(user)
    repo = user.github_repos.all.first
    headers = {
      "User-Agent" => A_USER_AGENT,
      "If-Modified-Since" => repo[:imported_at].httpdate
    }
    url = "#{A_API_URL}/user?access_token=#{URI.escape(user.github_token)}"
   
    response = self.head(url, headers: headers)
    response.code != 304
  end

  def self.bm(user, n = 1)
    Benchmark.measure do
      n.times {|i| Github.user_repos_changed?(user)}
    end
  end
  def self.user_repos(user, url = nil, page = 1, per_page = 20)
    headers = {"User-Agent" => A_USER_AGENT}
    if url.nil?
      url =  "#{A_API_URL}/user/repos?page=#{page}&per_page=#{per_page}&access_token=#{user.github_token}"
    end

    response  = self.get(url, headers: headers)
    paging_links = parse_paging_links(response.headers)
    
    repos = {
      repos: JSON.parse(response.body),
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

  def self.user_repo_names( github_token )
    repo_names = Array.new
    page = 1
    loop do
      body  = HTTParty.get("https://api.github.com/user/repos?access_token=#{github_token}&page=#{page}", :headers => {"User-Agent" => A_USER_AGENT } ).response.body
      repos = JSON.parse( body )
      break if ( repos.nil? || repos.empty? )
      repo_names += extract_repo_names( repos )
      page += 1
    end
    repo_names
  end

  def self.orga_repo_names( github_token )
    orga_names = self.orga_names github_token
    repo_names = self.repo_names_for_orgas github_token, orga_names
  end

  def self.repo_names_for_orgas( github_token, organisations )
    repo_names = Array.new
    organisations.each do |orga|
      repo_names += self.repo_names_for_orga( github_token, orga )
    end
    repo_names
  end

  def self.repo_names_for_orga( github_token, organisation_name )
    repo_names = Array.new
    page = 1
    loop do
      body = HTTParty.get("https://api.github.com/orgs/#{organisation_name}/repos?access_token=#{github_token}&page=#{page}", :headers => {"User-Agent" => A_USER_AGENT} ).response.body
      repos = JSON.parse( body )
      break if ( repos.nil? || repos.empty? )
      repo_names += extract_repo_names( repos )
      page += 1
    end
    repo_names
  end

  def self.orga_names( github_token )
    body = HTTParty.get("https://api.github.com/user/orgs?access_token=#{github_token}", :headers => {"User-Agent" => A_USER_AGENT} ).response.body
    organisations = JSON.parse( body )
    message = get_message( organisations )
    names = Array.new
    if organisations.nil? || organisations.empty? || !message.nil?
      return names
    end
    organisations.each do |organisation|
      names << organisation['login']
    end
    names
  end

  def self.private_repo?( github_token, name )
    body = HTTParty.get("https://api.github.com/repos/#{name}?access_token=#{github_token}", :headers => {"User-Agent" => A_USER_AGENT} ).response.body
    repo = JSON.parse( body )
    repo['private']
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    return false
  end

  def self.get_repo_sha(git_project, token)
    heads = JSON.parse HTTParty.get("https://api.github.com/repos/#{git_project}/git/refs/heads?access_token=" + URI.escape(token), :headers => {"User-Agent" => A_USER_AGENT}  ).response.body
    heads.each do |head|
      if head['url'].match(/heads\/master$/)
        return head['object']['sha']
      end
    end
    nil
  end

  def self.get_project_info(git_project, sha, token)
    result = Hash.new
    url = "https://api.github.com/repos/#{git_project}/git/trees/#{sha}?access_token=" + URI.escape(token)
    tree = JSON.parse HTTParty.get( url, :headers => {"User-Agent" => A_USER_AGENT} ).response.body
    tree['tree'].each do |file|
      name = file['path']
      result['url'] = file['url']
      result['name'] = name
      type = Project.type_by_filename( name )
      if type
        result['type'] = type
        return result
      end
    end
    return Hash.new
  end

  def self.fetch_file( url, token )
    JSON.parse HTTParty.get( "#{url}?access_token=" + URI.escape(token), :headers => {"User-Agent" => A_USER_AGENT} ).response.body
  end

  def self.supported_languages()
    Set['java', 'ruby', 'python', 'node.js', 'php', 'javascript',
        'coffeescript', 'clojure']
  end

  private

    def self.language_supported?(lang)
      return false if lang.nil?
      lang.casecmp('Java') == 0 ||
      lang.casecmp('Ruby') == 0 ||
      lang.casecmp('Python') == 0 ||
      lang.casecmp('Node.JS') == 0 ||
      lang.casecmp("CoffeeScript") == 0 ||
      lang.casecmp("JavaScript") == 0 ||
      lang.casecmp("PHP") == 0 ||
      lang.casecmp("Clojure") == 0
    end

    def self.get_message( repositories )
      repositories['message']
    rescue => e
      # by default here should be no message or nil
      # We expect that everything is ok and there is no error message
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.first
      nil
    end

    def self.extract_repo_names( repos )
      message = get_message( repos )
      repo_names = Array.new
      if repos.nil? || repos.empty? || !message.nil?
        return repo_names
      end
      repos.each do |repo|
        lang = repo['language']
        repo_names << repo['full_name'] if self.language_supported?( lang )
      end
      repo_names
    end

end
