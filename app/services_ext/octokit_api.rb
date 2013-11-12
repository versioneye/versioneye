require 'octokit'

class OctokitApi

  @@github_api = nil

  # Singleton pattern
  def self.get_instance
    return @@github_api if @@github_api
    client = Octokit::Client.new :client_id => Settings.github_client_id, :client_secret => Settings.github_client_secret
    @@github_api = client.root
    @@github_api
  end

end
