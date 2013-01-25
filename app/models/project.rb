class Project

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :name, type: String
    
  field :project_type, type: String, :default => "Maven2"
  field :project_key, type: String
  field :private_project, type: Boolean, :default => false
  field :period, type: String, :default => "weekly"
  field :email, type: String
  field :url, type: String
  field :source, type: String, :default => "upload"  # possible values => [upload, url, github]
  field :s3_filename, type: String
  field :github_project, type: String
  field :dep_number, type: Integer
  field :out_number, type: Integer, default: 0
  field :unknown_number, type: Integer, default: 0
  
  attr_accessor :dependencies

  validates :name, presence: true
  validates :project_key, presence: true, uniqueness: true

  scope :by_user, ->(user){ where(user_id: user.id) }

  before_save :make_project_key!

  def self.find_by_id( id )
    Project.find(id)
  rescue => e
    p "#{e}"
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
    self.dependencies
  end

  def user
    return User.find_by_id(user_id) if user_id
    return nil
  end

  def get_outdated_dependencies
    fetch_dependencies
    outdated_dependencies = Array.new
    self.dependencies.each do |dep|
      outdated_dependencies << dep if dep.outdated
    end
    outdated_dependencies
  end

  def get_known_dependencies
    fetch_dependencies
    known_dependencies = Array.new
    self.dependencies.each do |dep|
      known_dependencies << dep if dep.prod_key
    end
    known_dependencies
  end  

  def self.remove_dependencies(project)
    project.fetch_dependencies
    project.dependencies.each do |dep|
      dep.remove
    end
  end

  def self.save_dependencies(project, dependencies)
    project.dependencies = Array.new
    dependencies.each do |dep|
      project.dependencies << dep
      dep.project_id = project.id.to_s
      dep.user_id = project.user_id
      dep.save
    end
  end

  def self.update_dependencies(period="weekly")
    projects = Project.all()
    projects.each do |project|
      if project.period.eql?( period )
        Project.process_project ( project )
      end
    end
  end

  def make_project_key
    if self.user_id.nil? 
      return Project.create_random_value()
    end
    project_nr = 1
    project_key_text = "#{self.project_type}_#{self.name}".downcase
    similar_projects = Project.by_user(self.user).where(
                        name: self.name,
                        project_type: self.project_type  
                      )

    project_nr += similar_projects.count unless similar_projects.nil?
    if project_nr > 1
      new_project_key =  "#{project_key_text}_#{project_nr}"
    else
      new_project_key = project_key_text
    end
    new_project_key
  end

  def make_project_key!
    self.project_key = make_project_key # unless self.project_key
  end

  def self.process_project( project )
    if project.user_id.nil?
      return nil
    end
    if project.source.eql?("github")
      Project.update_from_github( project )
    end
    if project.s3_filename && !project.s3_filename.empty?
      project.url = Project.get_project_url_from_s3( project.s3_filename )
    end
    p "user: #{project.user.username}  #{project.name} url: #{project.url}"
    p " - old: deps: #{project.dep_number} - out: #{project.out_number}"
    new_project = Project.create_from_file( project.project_type, project.url )
    p " - new: deps: #{new_project.dep_number} - out: #{new_project.out_number}"
    if new_project.dependencies && !new_project.dependencies.empty? 
      Project.remove_dependencies(project)
      Project.save_dependencies(project, new_project.dependencies)
      project.out_number = new_project.out_number
      project.dep_number = new_project.dep_number
      project.unknown_number = new_project.unknown_number
      project.save
      if project.out_number > 0
        ProjectMailer.projectnotification_email(project).deliver
      end
    end
  rescue => e
    p "ERROR in proccess_project #{e}"
    e.backtrace.each do |message|
      p "#{message}"
    end
    nil
  end

  def self.update_from_github( project )
    github_project = project.github_project
    current_user = project.user
    sha = Project.get_repo_sha_from_github( github_project, current_user.github_token )
    project_info = Project.get_project_info_from_github( github_project, sha, current_user.github_token )
    if project_info.empty?
      return nil
    end
    s3_infos = Project.fetch_file_from_github(project_info['url'], current_user.github_token, project_info['name'])
    if s3_infos['filename'] && s3_infos['s3_url']
      delete_project_from_s3( project.s3_filename )
      project.s3_filename = s3_infos['filename']
      project.url = s3_infos['s3_url']
      project.save
    end
  end
  
  def self.create_from_file(project_type, url)
    project = nil
    if project_type.eql?("Maven2")
      project = PomParser.parse ( url )
    elsif project_type.eql?("RubyGems")
      if url.match(/Gemfile\.lock/)
        project = GemfilelockParser.parse ( url )
      else 
        project = GemfileParser.parse ( url )
      end
    elsif project_type.eql?("PIP")
      project = RequirementsParser.parse ( url )
    elsif project_type.eql?("npm")
      project = PackageParser.parse ( url )
    elsif project_type.eql?("composer")
      project = ComposerParser.parse ( url )
    elsif project_type.eql?("gradle")
      project = GradleParser.parse ( url )
    elsif project_type.eql?("Lein")
      project = LeinParser.parse ( url )
    end
    project
  rescue => e 
    p "exception: #{e}"
    e.backtrace.each do |message|
      p "#{message}"
    end
    project = Project.new
  end
  
  def self.sanitize_filename(file_name)
    just_filename = File.basename(file_name)
    just_filename.sub(/[^\w\.\-]/,'_')
  end

  def self.upload_to_s3( fileUp )
    orig_filename =  fileUp['datafile'].original_filename
    fname = Project.sanitize_filename(orig_filename)
    random = Project.create_random_value
    filename = "#{random}_#{fname}"
    AWS::S3::S3Object.store(filename, 
      fileUp['datafile'].read, 
      Settings.s3_projects_bucket, 
      :access => "private")
    filename
  end

  def self.get_project_url_from_s3 filename
    AWS::S3::S3Object.url_for(filename, Settings.s3_projects_bucket, :authenticated => true)
  end

  def self.delete_project_from_s3 filename
    AWS::S3::S3Object.delete filename, Settings.s3_projects_bucket
  end

  def self.get_repo_sha_from_github(git_project, token)
    heads = JSON.parse HTTParty.get("https://api.github.com/repos/#{git_project}/git/refs/heads?access_token=" + URI.escape(token) ).response.body
    heads[0]['object']['sha']
  end

  def self.get_project_info_from_github(git_project, sha, token)
    result = Hash.new
    tree = JSON.parse HTTParty.get("https://api.github.com/repos/#{git_project}/git/trees/#{sha}?access_token=" + URI.escape(token) ).response.body
    tree['tree'].each do |file|
      name = file['path']
      if name.eql?("Gemfile")
        result['url'] = file['url']
        result['name'] = name
        result['type'] = "RubyGems"
      elsif name.eql?("Gemfile.lock")
        result['url'] = file['url']
        result['name'] = name
        result['type'] = "RubyGems"
      elsif name.eql?("pom.xml")
        result['url'] = file['url']
        result['name'] = name
        result['type'] = "Maven2"
      elsif name.eql?("requirements.txt")
        result['url'] = file['url']
        result['name'] = name
        result['type'] = "PIP"
      elsif name.eql?("package.json")
        result['url'] = file['url']
        result['name'] = name
        result['type'] = "npm"
      end 
    end
    result
  end

  def self.fetch_file_from_github(url, token, filename)
    file = JSON.parse HTTParty.get( "#{url}?access_token=" + URI.escape(token) ).response.body
    file_bin = file['content']
    random_value = Project.create_random_value
    new_filename = "#{random_value}_#{filename}"
    AWS::S3::S3Object.store(
      new_filename, 
      Base64.decode64(file_bin), 
      Settings.s3_projects_bucket,
      :access => "private")
    url = Project.get_project_url_from_s3(new_filename)
    result = Hash.new
    result['filename'] = new_filename
    result['s3_url'] = url
    result
  end

  def self.create_random_value
    chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    value = ""
    20.times { value << chars[rand(chars.size)] }
    value
  end

  def self.get_email_for(project, user)
    if project.email.nil? || project.email.empty? 
      return user.email
    end
    user_email = user.get_email( project.email )
    if user_email && user_email.verified?
      return user_email.email
    end
    return user.email 
  end
  
end
