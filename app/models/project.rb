class Project

  include Mongoid::Document
  include Mongoid::Timestamps

  A_TYPE_RUBYGEMS = "RubyGems" # TODO Check doublets with "RubyGem" withous "s" !!!
  A_TYPE_PIP      = "PIP"
  A_TYPE_NPM      = "npm"
  A_TYPE_COMPOSER = "composer"
  A_TYPE_GRADLE   = "gradle"
  A_TYPE_MAVEN2   = "Maven2"
  A_TYPE_LEIN     = "Lein"
  A_TYPE_GITHUB   = "GitHub"

  A_SOURCE_UPLOAD = "upload"
  A_SOURCE_URL    = "url"
  A_SOURCE_GITHUB = "github"

  A_PERIOD_WEEKLY = "weekly"
  A_PERIOD_DAILY  = "daily"

  field :user_id, type: String
  field :name, type: String
  field :description, type: String 
  field :license, type: String 

  field :project_type, type: String, :default => A_TYPE_MAVEN2
  field :language, type: String
  field :project_key, type: String
  field :private_project, type: Boolean, :default => false
  field :period, type: String, :default => A_PERIOD_WEEKLY
  field :email, type: String
  field :url, type: String
  field :source, type: String, :default => A_SOURCE_UPLOAD
  field :s3_filename, type: String
  field :github_project, type: String
  field :dep_number, type: Integer
  field :out_number, type: Integer, default: 0
  field :unknown_number, type: Integer, default: 0
  field :public, type: Boolean, :default => false 

  attr_accessor :dependencies

  validates :name, presence: true
  validates :project_key, presence: true

  scope :by_user, ->(user){ where(user_id: user.id) }

  def self.find_by_id( id )
    Project.find(id)
  rescue => e
    p "ERROR in find_by_id #{e}"
    e.backtrace.each do |message|
      p "#{message}"
    end
    nil
  end
  
  def self.find_by_user user_id
    Project.all(conditions: { user_id: user_id } ).desc(:private_project).asc(:name)
  end

  def self.find_private_projects_by_user user_id
    Project.all(conditions: { user_id: user_id, private_project: true } )
  end

  def fetch_dependencies
    self.dependencies = Projectdependency.all(conditions: {project_id: self.id} ).desc(:outdated).desc(:release).asc(:prod_key)
    self.dependencies # This 2nd line is by purpose! Don't delete it! 
  end

  def user
    return User.find_by_id(user_id) if user_id
    return nil
  end

  def outdated_dependencies
    fetch_dependencies
    outdated_dependencies = Array.new
    self.dependencies.each do |dep|
      outdated_dependencies << dep if dep.outdated
    end
    outdated_dependencies
  end

  def known_dependencies
    fetch_dependencies
    knows_deps = Array.new
    self.dependencies.each do |dep|
      knows_deps << dep if dep.prod_key
    end
    knows_deps
  end  

  def remove_dependencies
    fetch_dependencies
    dependencies.each do |dependency|
      dependency.remove
    end
  end

  def save_dependencies
    dependencies.each do |dep|
      dep.project_id = self.id.to_s
      dep.user_id = self.user_id
      dep.save
      p "save dep #{dep.id}"
    end
  end

  def overwrite_dependencies( new_dependencies )
    remove_dependencies
    self.dependencies = Array.new( new_dependencies )
    save_dependencies
  end

  def make_project_key!
    self.project_key = make_project_key unless self.project_key
  end

  def make_project_key
    return Project.create_random_value() if self.user_id.nil? 
    project_nr = 1
    project_key_text = "#{self.project_type}_#{self.name}".downcase
    project_key_text.gsub!(/[\s|\W|\_]+/, "_")

    similar_projects = Project.by_user(self.user).where(
                        name: self.name,
                        project_type: self.project_type  
                      )
    project_nr += similar_projects.count unless similar_projects.nil?
    "#{project_key_text}_#{project_nr}"
  end

  def update_from new_project 
    self.overwrite_dependencies( new_project.dependencies )
    self.description = new_project.description
    self.license = new_project.license
    self.s3_filename = new_project.s3_filename
    self.dep_number = new_project.dep_number
    self.out_number = new_project.out_number
    self.unknown_number = new_project.unknown_number
    self.save
  end

  def self.type_by_filename( filename )
    trimmed_name = filename.split("?")[0]
    return A_TYPE_RUBYGEMS if trimmed_name.match(/Gemfile$/) or trimmed_name.match(/Gemfile.lock$/)
    return A_TYPE_COMPOSER if trimmed_name.match(/composer.json$/) or trimmed_name.match(/composer.lock$/)
    return A_TYPE_PIP      if trimmed_name.match(/requirements.txt$/) or trimmed_name.match(/setup.py$/)
    return A_TYPE_NPM      if trimmed_name.match(/package.json$/)
    return A_TYPE_GRADLE   if trimmed_name.match(/.gradle$/)
    return A_TYPE_MAVEN2   if trimmed_name.match(/pom.xml$/)
    return A_TYPE_LEIN     if trimmed_name.match(/project.clj$/)
    return nil
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
