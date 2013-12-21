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
  field :git_url     , type: String
  field :html_url    , type: String
  field :forks       , type: Integer
  field :watchers    , type: Integer
  field :size        , type: Integer
  field :etag        , type: String
  field :branches    , type: Array
  field :project_files, type: Hash,    :default => nil
  field :created_at  , type: DateTime, :default => DateTime.new
  field :updated_at  , type: DateTime, :default => DateTime.new #when github repo was updated
  field :pushed_at   , type: DateTime, :default => DateTime.new
  field :cached_at   , type: DateTime, :default => DateTime.new

  belongs_to :user

  scope :by_language   , ->(lang){where(language: lang)}
  scope :by_user       , ->(user){where(user_id: user._id)}
  scope :by_owner_login, ->(login){where(owner_login: login)}
  scope :by_owner_type , ->(type_name){where(owner_type: type_name)}
  scope :by_org        , ->(org_name){where(owner_login: org_name, owner_type: "organization")}
  scope :by_fullname   , ->(fullname){where(fullname: fullname)}


  def self.get_owner_type(user, owner_info)
    owner_type = "unknown"

    if user[:github_login].nil?
      user_info = Github.user(user.github_token)
      user_login = user_info[:login]
      user.update_attributes({github_login: user_login})
    else
      user_login = user[:github_login]
    end

    case owner_info[:type].to_s.downcase
    when 'organization'
      owner_type = 'organization'
    when 'user'
      if user_login != owner_info[:login] then
        owner_type = 'team'
      else
        owner_type = "user"
      end
    else
      owner_type = 'unknown'
    end

    owner_type
  end

  def self.build_new(user, repo, etag = nil)
    return false if repo.nil? || repo.empty?
    repo = repo.deep_symbolize_keys

    owner_info = repo[:owner]
    owner_type = get_owner_type(user, repo[:owner])
    new_repo = GithubRepo.new({
      user_id: user.id,
      github_id: repo[:id],
      name: repo[:name],
      fullname: repo[:full_name],
      user_login: user[:user_login],
      owner_login: owner_info[:login],
      owner_type: owner_type,
      owner_avatar: owner_info[:avatar_url],
      language: repo[:language].to_s.downcase,
      description: repo[:description],
      private: repo[:private],
      fork: repo[:fork],
      github_url: repo[:url],
      homepage: repo[:homepage],
      git_url: repo[:git_url],
      html_url: repo[:html_url],
      forks: repo[:forks],
      watchers: repo[:watchers],
      size: repo[:size],
      etag: etag.to_s,
      branches: repo[:branches],
      project_files: repo[:project_files],
      created_at: repo[:created_at],
      updated_at: repo[:updated_at],
      pushed_at: repo[:pushed_at],
      cached_at: DateTime.now
    })

    new_repo
  end

  def self.create_new(user, repo, etag = nil)
    new_repo = build_new(user, repo, etag)
    unless new_repo.save
      Rails.logger.error "Cant save new repo:#{new_repo.errors.full_messages.to_sentence}"
    end
    new_repo
  end

end
