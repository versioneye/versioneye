class GithubRepo

  require 'will_paginate/array'

  include Mongoid::Document

  field :github_id   , type: String
  field :name        , type: String
  field :fullname    , type: String
  field :user_login  , type: String
  field :owner_login , type: String
  field :owner_type  , type: String
  field :owner_avatar, type: String
  field :language    , type: String
  field :description , type: String
  field :private     , type: Boolean, default: false
  field :fork        , type: Boolean, default: false
  field :github_url  , type: String
  field :homepage    , type: String
  field :size        , type: Integer
  field :etag        , type: String
  field :branches    , type: Array
  field :created_at  , type: DateTime
  field :updated_at  , type: DateTime #when github repo was updated
  field :pushed_at   , type: DateTime
  field :cached_at , type: DateTime
  field :refreshed_at, type: DateTime #when this doc updated

  belongs_to :user

  scope :by_language, ->(lang){where(language: lang)}
  scope :by_user, ->(user){where(user_id: user._id)}
  scope :by_owner_login, ->(login){where(owner_login: login)}
  scope :by_owner_type, ->(type_name){where(owner_type: type_name)}
  scope :by_org, ->(org_name){where(owner_login: org_name, owner_type: "organization")}

  def self.add_new(user, repo, etag = nil)
    return false if repo.nil? || repo.empty?
    if repo['owner'].nil?
      Rails.console.error("Repo #{full_name} is missing owner. Adding as unknown.")
      repo['owner'] = {'type' => "ufo"}
    end
    case repo['owner']['type'].to_s.downcase
    when 'organization'
      owner_type = 'organization'
    when 'user'
      Rails.logger.debug("Adding new repo with userLogin: ")
      Rails.logger.debug(user[:user_login])
      if user[:user_login] != repo['owner']['login'] then
        owner_type = 'team'
      else
        owner_type = "user"
      end
    else
      owner_type = 'unknown'
    end

    new_repo = GithubRepo.new({
      user_id: user.id,
      github_id: repo['id'],
      name: repo['name'],
      fullname: repo['full_name'],
      user_login: user[:user_login],
      owner_login: repo['owner']['login'],
      owner_type: owner_type,
      owner_avatar: repo['owner']['avatar_url'],
      language: repo['language'].to_s.downcase,
      description: repo['description'],
      private: repo['private'],
      fork: repo['fork'],
      github_url: repo['url'],
      homepage: repo['homepage'],
      size: repo['size'],
      etag: etag.to_s,
      branches: repo['branches'],
      created_at: repo['created_at'],
      updated_at: repo['updated_at'],
      pushed_at: repo['pushed_at'],
      cached_at: DateTime.now
    })
    new_repo.save
  end

end
