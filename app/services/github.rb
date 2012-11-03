class Github

  def self.repository_names( github_token )
    body = HTTParty.get("https://api.github.com/user/repos?access_token=#{github_token}").response.body
    repos = JSON.parse( body )
    extract_repo_names( repos )
  end

  def self.all_orga_repo_names( github_token )
    orga_names = self.organisation_names github_token
    repo_names = self.organisations_repository_names github_token, orga_names
  end

  def self.organisations_repository_names( github_token, organisations )
    repo_names = Array.new
    organisations.each do |orga| 
      repo_names += self.organisation_repository_names( github_token, orga )
    end
    repo_names
  end

  def self.organisation_repository_names( github_token, organisation_name )
    body = HTTParty.get("https://api.github.com/orgs/#{organisation_name}/repos?access_token=#{github_token}").response.body
    repos = JSON.parse( body )
    extract_repo_names( repos )
  end

  def self.organisation_names( github_token )
    body = HTTParty.get("https://api.github.com/user/orgs?access_token=#{github_token}").response.body
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
    body = HTTParty.get("https://api.github.com/repos/#{name}?access_token=#{github_token}").response.body
    repo = JSON.parse( body )
    repo['private']
  rescue => e
    p "ERROR in is_private_repo - #{e}"
    e.backtrace.each do |message| 
      p " - #{message}"
    end
    return false
  end

  private 

    def self.language_supported?(lang)
      lang.eql?('Java') || lang.eql?('Ruby') || 
      lang.eql?('Python') || lang.eql?('Node.JS') || 
      lang.eql?("CoffeeScript") || lang.eql?("JavaScript") || 
      lang.eql?("PHP") || 
      lang.eql?("Clojure") || lang.eql?("clojure")
    end

    def self.get_message( repositories )
      repositories['message']
    rescue => e
      # by default there should be no message. 
      # We expect that everything is ok and there is no error message
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