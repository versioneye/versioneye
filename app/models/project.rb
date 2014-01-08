class Project

  include Mongoid::Document
  include Mongoid::Timestamps

  A_TYPE_RUBYGEMS  = 'RubyGem'
  A_TYPE_PIP       = 'PIP'
  A_TYPE_NPM       = 'npm'
  A_TYPE_COMPOSER  = 'composer'
  A_TYPE_GRADLE    = 'gradle'
  A_TYPE_MAVEN2    = 'Maven2'
  A_TYPE_LEIN      = 'Lein'
  A_TYPE_BOWER     = 'Bower'
  A_TYPE_GITHUB    = 'GitHub'
  A_TYPE_R         = 'R'
  A_TYPE_COCOAPODS = 'CocoaPods'

  A_SOURCE_UPLOAD    = 'upload'
  A_SOURCE_URL       = 'url'
  A_SOURCE_GITHUB    = 'github'
  A_SOURCE_BITBUCKET = 'bitbucket'

  A_PERIOD_MONTHLY = 'monthly'
  A_PERIOD_WEEKLY  = 'weekly'
  A_PERIOD_DAILY   = 'daily'

  field :name       , type: String
  field :description, type: String
  field :license    , type: String

  field :project_type  , type: String,  :default => A_TYPE_MAVEN2
  field :language      , type: String
  field :project_key   , type: String
  field :period        , type: String,  :default => A_PERIOD_WEEKLY
  field :notify_after_api_update, type: Boolean, :default => false
  field :email         , type: String
  field :url           , type: String
  field :source        , type: String,  :default => A_SOURCE_UPLOAD
  field :s3_filename   , type: String

  field :scm_fullname  , type: String # repo name, for example 'reiz/gemify'
  field :scm_branch    , type: String, default: "master"

  field :dep_number    , type: Integer
  field :out_number    , type: Integer, :default => 0
  field :unknown_number, type: Integer, :default => 0
  field :public        , type: Boolean, :default => false   # visible for everybody

  field :private_project, type: Boolean, :default => false  # private project from GitHub
  field :api_created    , type: Boolean, :default => false  # this project was created through the VersionEye API

  validates :name       , presence: true
  validates :project_key, presence: true

  belongs_to :user
  has_many   :projectdependencies
  has_many   :collaborators, class_name: 'ProjectCollaborator'

  scope :by_user  , ->(user)  { where(user_id: user[:_id].to_s) }
  scope :by_collaborator, ->(user){all_in(_id: ProjectCollaborator.by_user(user).to_a.map(&:project_id))}
  scope :by_source, ->(source){ where(source:  source ) }
  scope :by_period, ->(period){ where(period:  period ) }
  scope :by_github, ->(reponame){ where(source: A_SOURCE_GITHUB, scm_fullname: reponame)}

  def to_s
    "<Project #{language}/#{project_type} #{name}>"
  end

  def dependencies
    self.projectdependencies
  end

  def sorted_dependencies_by_rank
    deps = self.dependencies
    return deps if deps.nil? or deps.empty?
    deps.sort_by {|dep| dep[:status_rank] }
  end

  def unmuted_dependencies
    deps = self.projectdependencies
    return nil if deps.nil?
    deps.any_in(muted: [false, nil])
  end

  def muted_dependencies
    deps = self.projectdependencies
    return nil if deps.nil?
    deps.any_in(muted: [true])
  end

  def self.find_by_id( id )
    Project.find( id )
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def filename
    self.s3_filename.to_s.gsub(/^\S+\_/, "")
  end

  def self.private_project_count_by_user user_id
    Project.where( user_id: user_id, private_project: true ).count
  end

  def show_dependency_badge?
    self.language.eql?(Product::A_LANGUAGE_JAVA) or self.language.eql?(Product::A_LANGUAGE_PHP) or
    self.language.eql?(Product::A_LANGUAGE_RUBY) or self.language.eql?(Product::A_LANGUAGE_NODEJS) or
    self.language.eql?(Product::A_LANGUAGE_CLOJURE) or self.language.eql?(Product::A_LANGUAGE_OBJECTIVEC)
  end

  def visible_for_user?(user)
    return true if self[:public]
    return false if user.nil?

    is_collaborator = ProjectCollaborator.collaborator?(self[:_id], user[:_id])
    return true if self.user_id.to_s == user[:_id].to_s or is_collaborator
    false
  end

  def collaborator( user )
    return nil if user.nil?
    return nil if collaborators.nil? || collaborators.size == 0
    collaborators.each do |collaborator|
      return collaborator if user._id.to_s.eql?( collaborator.user_id.to_s )
    end
    nil
  end

  def collaborator?( user )
    return false if user.nil?
    return true if !self.user.nil? && self.user.username.eql?( user.username )
    !collaborator( user ).nil?
  end

  def remove_collaborators
    collaborators.each do |collaborator|
      collaborator.remove
    end
  end

  def outdated?
    self.projectdependencies.each do |dep|
      return true if dep.outdated?
    end
    false
  end

  def outdated_dependencies
    outdated_dependencies = Array.new
    self.projectdependencies.each do |dep|
      outdated_dependencies << dep if dep.outdated?
    end
    outdated_dependencies
  end

  def known_dependencies
    knows_deps = Array.new
    self.projectdependencies.each do |dep|
      knows_deps << dep if dep.prod_key
    end
    knows_deps
  end

  def remove_dependencies
    projectdependencies.each do |dependency|
      dependency.remove
    end
  end

  def save_dependencies
    projectdependencies.each do |dependency|
      dependency.save
    end
  end

  def muted_prod_keys
    prod_keys = Array.new
    muted_deps = muted_dependencies
    muted_deps.each do |dep|
      prod_keys.push "#{dep.language}_#{dep.prod_key}_#{dep.version_current}"
    end
    prod_keys
  end

  def overwrite_dependencies( new_dependencies )
    muted_keys = muted_prod_keys
    remove_dependencies
    new_dependencies.each do |dep|
      dep_key = "#{dep.language}_#{dep.prod_key}_#{dep.version_current}"
      dep.muted = true if muted_keys.include?( dep_key )
      projectdependencies.push dep
      dep.save
    end
  end

  def make_project_key!
    self.project_key = make_project_key unless self.project_key
  end

  def make_project_key
    return Project.create_random_value() if self.user.nil?
    project_nr = 1
    project_key_text = "#{self.project_type}_#{self.name}".downcase
    project_key_text.gsub!(/[\s|\W|\_]+/, "_")

    similar_projects = Project.by_user(self.user).where(
                        project_key: Regexp.new("#{project_key_text}"),
                        project_type: self.project_type
                      )
    project_nr += similar_projects.count unless similar_projects.nil?
    "#{project_key_text}_#{project_nr}"
  end

  def update_from new_project
    return nil if new_project.nil?
    if new_project.dependencies && !new_project.dependencies.empty?
      self.overwrite_dependencies( new_project.dependencies )
    end
    self.description    = new_project.description
    self.license        = new_project.license
    self.url            = new_project.url
    if new_project.s3_filename
      self.s3_filename  = new_project.s3_filename
    end
    self.dep_number     = new_project.dep_number
    self.out_number     = new_project.out_number
    self.unknown_number = new_project.unknown_number
    self.save
  end

  def self.email_for(project, user)
    if project.email.nil? || project.email.empty?
      return user.email
    end
    user_email = user.get_email( project.email )
    if user_email && user_email.verified?
      return user_email.email
    end
    return user.email
  end

  def self.create_random_value
    chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    value = ""
    20.times { value << chars[rand(chars.size)] }
    value
  end

end
