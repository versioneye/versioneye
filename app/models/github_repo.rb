class GithubRepo
  require 'will_paginate/array'

  include Mongoid::Document

  belongs_to :user

  field :github_id, type: String
  field :name, type: String
  field :fullname, type: String
  field :language, type: String
  field :description, type: String
  field :private, type: Boolean, default: false
  field :fork, type: Boolean, default: false
  field :github_url, type: String
  field :homepage, type: String
  field :size, type: Integer
  field :etag, type: String
  field :created_at, type: DateTime
  field :updated_at, type: DateTime #when github repo was updated
  field :pushed_at, type: DateTime
  field :imported_at, type: DateTime
  field :refreshed_at, type: DateTime #when this doc updated


  scope :by_language, ->(lang){where(language: lang)}
  scope :by_user, ->(user){where(user_id: user._id)}

  def self.add_new(user, repo, etag = nil)
    new_repo = GithubRepo.new({
      user_id: user.id,
      github_id: repo['id'],
      name: repo['name'],
      fullname: repo['full_name'],
      language: repo['language'].to_s.downcase,
      description: repo['description'],
      private: repo['private'],
      fork: repo['fork'],
      github_url: repo['url'],
      homepage: repo['homepage'],
      size: repo['size'],
      etag: etag.to_s,
      created_at: repo['created_at'],
      updated_at: repo['updated_at'],
      pushed_at: repo['pushed_at'],
      imported_at: DateTime.now
    })
    
    new_repo.save
  end

=begin
  Returns github repos for user;
  If user dont have yet any github repos 
     or there's been any change on user's github account, 
  then trys to read from github 
  else it returns cached results from GitHubRepos collection.
=end
  def self.cached_user_repos(user)
    if user.github_repos.all.count == 0
      url = nil
      begin
        data = Github.user_repos(user, url)
        data[:repos].each do |repo| 
          new_repo = GithubRepo.add_new(user, repo, data[:etag])
        end
        url = data[:paging]["next"]
      end while not url.nil?
    elsif Github.user_repos_changed?(user) 
        p "Repos are changed - going to re-import all user repos."
        user.github_repos.delete_all
        GithubRepo.cached_user_repos user
    else
        p "Nothing is changed - skipping update."
    end
    
    GithubRepo.by_user(user)
  end
end
