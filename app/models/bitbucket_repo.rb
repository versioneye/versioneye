class BitbucketRepo
  include Mongoid::Document
  require 'will_paginate/array'
  
  field :name         , type: String
  field :fullname     , type: String
  field :user_login   , type: String
  field :owner_login  , type: String
  field :owner_type   , type: String
  field :language     , type: String
  field :description  , type: String
  field :private      , type: Boolean, default: false
  field :scm          , type: String
  field :html_url     , type: String #web url
  field :clone_url    , type: String #clone url
  field :size         , type: Integer
  field :project_files, type: Hash, default: nil
  field :created_at   , type: DateTime, default: DateTime.new
  field :updated_at   , type: DateTime, default: DateTime.new
  field :cached_at    , type: DateTime, default: DateTime.new

  belongs_to :user

  scope :by_language    , ->(lang){where(language: lang)}
  scope :by_user        , ->(user){where(user_id: user[:_id])}
  scope :by_owner_login , ->(owner){where(owner_login: owner)} 
  scope :by_fullname    , ->(name){where(fullname: name)}

  def self.get_owner_type(user, owner_info)
    owner_type = 'team'
    if user[:bitbucket_id] == owner_info[:username]
      owner_type = 'user'
    end

    return owner_type
  end

  def self.build_new(user, repo, repo_branches = nil, project_files = nil)
    return if repo.nil? || repo.empty?
    owner_info = repo[:owner]
    owner_type = get_owner_type(user, owner_info)
    repo_links = repo[:links]

    new_repo = BitbucketRepo.new({
      user_id: user[:_id],
      user_login: user[:bitbucket_id],
      name: repo[:name],
      fullname: repo[:full_name],
      scm: repo[:scm],
      owner_login: owner_info[:username],
      owner_type: owner_type,
      language: repo[:language].to_s.downcase,
      description: repo[:description],
      private: repo[:is_private],
      html_url: repo_links[:html][:href],
      clone_url: repo_links[:clone].to_a.last[:href],
      size: repo[:size],
      branches: repo_branches,
      project_files: project_files,
      created_at: DateTime.parse(repo[:created_on]),
      updated_at: DateTime.parse(repo[:updated_on]),
      cached_at: DateTime.now
    })

    new_repo
  end

  def self.create_new(user, repo, repo_branches = nil, project_files = nil)
    new_repo = build_new(user, repo, repo_branches, project_files)
    unless new_repo.save
      Rails.logger.error "Cant save new repo:#{new_repo.errors.full_messages.to_sentence}"
    end
    new_repo
  end
end

