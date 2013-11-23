require 'octokit'

class OctokitApi

  def self.application_authentication
    # { :login => Settings.github_user, :password => Settings.github_pass }
    { :client_id => Settings.github_client_id, :client_secret => Settings.github_client_secret }
  end

  # Singleton pattern
  def self.client
    @@client ||= Octokit::Client.new(self.application_authentication)
  end

  # Singleton pattern
  # returns root
  def self.instance
    @@github_api ||= self.client.root
  end

end
