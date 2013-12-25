require 'oauth'

class Bitbucket
  A_API_URL = "https://bitbucket.org"
  A_API_V2_PATH = "/api/2.0"
  A_API_V1_PATH = "/api/1.0"
  A_DEFAULT_HEADERS = {"User-Agent" => "Chrome28 (info@versioneye.com)"}
 
  @@api_key = Settings.bitbucket_token
  @@api_secret = Settings.bitbucket_secret

  def self.consumer_key 
   @@api_key 
  end
  
  def self.init_oauth_client
    OAuth::Consumer.new(@@api_key, @@api_secret, 
                       site: A_API_URL,
                       request_token_path: "/api/1.0/oauth/request_token",
                       authorize_path: "/api/1.0/oauth/authenticate",
                       access_token_url: "/api/1.0/oauth/access_token")
  end

  def self.request_token(callback_url)
    oauth = init_oauth_client
    oauth.get_request_token(oauth_callback: callback_url)
  end

  #returns user information for authorized user
  def self.user(token, secret)
    path = "#{A_API_V1_PATH}/user"
    response = get_json(path, token, secret)
    response[:user] if  response.is_a?(Hash)
  end

  #returns bitbuckets' profile info for username
  def self.user_info(user_name, token, secret)
    return if user_name.to_s.strip.empty?
    path = "#{A_API_V2_PATH}/users/#{user_name}"
    get_json(path, token, secret)
  end

  def self.user_orgs(user)
    path = "#{A_API_V1_PATH}/user/privileges"
    data = get_json(path, user[:bitbucket_token], user[:bitbucket_secret])
    return if data.to_a.empty?
    data[:teams].keys
  end

  def self.read_repos(user_name, token, secret)
    path = "#{A_API_V2_PATH}/repositories/#{user_name}"
    repos = []
    while true do
      data = get_json(path, token, secret)
      repos.concat(data[:values]) if data.has_key?(:values)

      break if !data.has_key?(:next) or data[:next].to_s.empty?
      path = data[:next]
    end
    repos
  end

  def self.repo_info(repo_name, token, secret)
    path = "#{A_API_V2_PATH}/repositories/#{repo_name}"
    get_json(path, token, secret)
  end

  def self.repo_branches(repo_name, token, secret)
    path  = "#{A_API_V1_PATH}/repositories/#{repo_name}/branches"
    data = get_json(path, token, secret)
    return if data.nil?

    branches = []
    data.each_pair {|k, v| branches << v[:branch]}
    branches
  end

  def self.repo_project_files(repo_name, token, secret)
    branches = repo_branches(repo_name, token, secret)
    return if branches.to_a.empty?
    files = {}
    branches.each do |branch|
      files[branch] =  project_files_from_branch(repo_name, branch, token, secret)
    end
    files
  end

  def self.repo_branch_tree(repo_name, branch, token, secret)
    path = "#{A_API_V1_PATH}/repositories/#{repo_name}/src/#{branch}/"
    get_json(path, token, secret)
  end

  def self.project_files_from_branch(repo_name, branch, token, secret)
    branch_tree = repo_branch_tree(repo_name, branch, token, secret)
    if branch_tree.nil?
      Rails.logger.error "Didnt get branch tree for #{repo_name}/#{branch}."
      return
    end

    project_files = branch_tree[:files].keep_if do |file_info|
      ProjectService.type_by_filename(file_info[:path]) != nil
    end
    project_files.each {|file| file[:uuid] = SecureRandom.hex }
    project_files
  end

  def self.fetch_project_file_from_branch(repo_name, branch, filename, token, secret)
    path = "#{A_API_V1_PATH}/repositories/#{repo_name}/raw/#{branch}/#{filename}"
    get_json(path, token, secret, true)
  end

  def self.get_json(path, token, secret, raw = false, params = {}, headers = {})
    url = "#{A_API_URL}#{path}"
    oauth = init_oauth_client
    token = OAuth::AccessToken.new(oauth, token, secret)
    oauth_params = {consumer: oauth, token: token, request_uri: url}
    request_headers = A_DEFAULT_HEADERS 
    request_headers.merge! headers

    response = token.get(path, request_headers)
    if raw == true
      return response.body
    end

    begin
      JSON.parse(response.body, symbolize_names: true) 
    rescue => e
      Rails.logger.error e.message
      Rails.logger.error "Got status: #{response.code} #{response.message} body: #{response.body}"
      Rails.logger.error e.backtrace.join("\n")
    end
 end
end
