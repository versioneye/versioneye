class ProjectService

  def self.type_by_filename( filename )
    trimmed_name = filename.split("?")[0]
    return Project::A_TYPE_RUBYGEMS if trimmed_name.match(/Gemfile$/)          or trimmed_name.match(/Gemfile.lock$/)
    return Project::A_TYPE_COMPOSER if trimmed_name.match(/composer.json$/)    or trimmed_name.match(/composer.lock$/)
    return Project::A_TYPE_PIP      if trimmed_name.match(/requirements.txt$/) or trimmed_name.match(/setup.py$/) or trimmed_name.match(/pip.log$/)
    return Project::A_TYPE_NPM      if trimmed_name.match(/package.json$/)
    return Project::A_TYPE_GRADLE   if trimmed_name.match(/.gradle$/)
    return Project::A_TYPE_MAVEN2   if trimmed_name.match(/pom.xml$/) or trimmed_name.match(/pom.json$/)
    return Project::A_TYPE_LEIN     if trimmed_name.match(/project.clj$/)
    return nil
  end

  def self.store( project )
    if project.nil?
      Rails.logger.error "Project can't be nil. Some error with importing."
      return nil
    end
    project.make_project_key!
    if project.dependencies && !project.dependencies.empty? && project.save
      project.save_dependencies
      return true
    else
      Rails.logger.error "Can't save project: #{project.errors.full_messages.to_json}"
      return false
    end
  end

  def self.update_all( period )
    update_projects period
    update_collaborators_projects period
  end

  def self.update_projects( period )
    projects = Project.by_period( period )
    projects.each do |project|
      self.update( project, true )
    end
  end

  def self.update_collaborators_projects( period )
    collaborators = ProjectCollaborator.by_period( period )
    collaborators.each do |collaborator|
      project = collaborator.project
      user    = collaborator.user
      if project.nil? || user.nil?
        collaborator.remove
        next
      end
      project = self.update( project, false )
      if project.out_number > 0
        p "send out email notification to collaborator #{user.fullname} for #{project.name}."
        ProjectMailer.projectnotification_email( project, user ).deliver
      end
    end
  end

  def self.update( project, send_email = false )
    return nil if project.nil? || project.user_id.nil?
    self.update_url( project )
    new_project = self.build_from_url( project.url )
    project.update_from( new_project )
    if send_email && project.out_number > 0
      p "send out email notification for project: #{project.name} to user #{project.user.fullname}"
      ProjectMailer.projectnotification_email( project ).deliver
    end
    project
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    nil
  end

  def self.update_url( project )
    if project.source.eql?( Project::A_SOURCE_GITHUB )
      self.update_project_file_from_github( project )
    end
    if project.s3_filename && !project.s3_filename.empty?
      project.url = S3.url_for( project.s3_filename )
    end
  end

  def self.update_project_file_from_github( project )
    project_file = Github.project_file_from_branch( project.user, project.github_project, project.github_branch )
    return nil if project_file.nil? || project_file.empty?
    s3_infos = S3.upload_github_file( project_file, project_file['name'] )
    if s3_infos['filename'] && s3_infos['s3_url']
      S3.delete( project.s3_filename )
      project.s3_filename = s3_infos['filename']
      project.url         = s3_infos['s3_url']
      project.save
    end
  end

=begin
  This methods is doing 3 things
   - Importing a project_file from GitHub
   - Parsing the project_file to a new project
   - Storing the new project to DB
=end
  def self.import_from_github(user, repo_name, branch = "master")
    private_project = Github.private_repo?(user.github_token, repo_name)
    if private_project && !ProjectService.is_allowed_to_add_private_project?(user)
      error_msg = "You selected a private project. Please upgrade your plan to monitor the selected project."
      return error_msg
    end

    project_file = Github.project_file_from_branch( user, repo_name, branch )
    if project_file.nil?
      error_msg = " Didn't find any project file of a supported package manager."
      Rails.logger.error " Can't import project file from #{repo_name} branch #{branch} "
      return error_msg
    end

    s3_info = S3.upload_github_file( project_file, project_file['name'] )
    if s3_info.nil? && !s3_info.has_key?('filename') && !s3_info.has_key?('s3_url')
      error_msg = "Connectivity issues - can't import project file for parsing."
      Rails.logger.error " Can't upload file to s3: #{project_file['name']}"
      return error_msg
    end

    parsed_project = build_from_url s3_info['s3_url']
    parsed_project.update_attributes({
      name: repo_name,
      project_type: project_file['type'],
      user_id: user.id.to_s,
      source: Project::A_SOURCE_GITHUB,
      github_project: repo_name,
      private_project: private_project,
      github_branch: branch,
      s3_filename: s3_info['filename'],
      url: s3_info['s3_url']
    })

    return parsed_project if store( parsed_project )
  end

  def self.build_from_url( url )
    project_type = type_by_filename( url )
    parser       = ParserStrategy.parser_for( project_type, url )
    parser.parse url
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    project = Project.new
  end

  def self.destroy project_id
    project = Project.find_by_id( project_id )
    if project.s3_filename && !project.s3_filename.empty?
      S3.delete( project.s3_filename )
    end
    project.remove_dependencies
    project.remove_collaborators
    project.remove
  end

  # TODO write test
  def self.is_allowed_to_add_private_project?( user )
    private_projects = Project.find_private_projects_by_user( user.id )
    plan = user.plan
    if plan.nil? || plan.private_projects <= private_projects.count
      return false
    else
      return true
    end
  end

  # Returns a map with
  #  - :key => "language_prod_key"
  #  - :value => "Array of project IDs where the prod_key is used"
  def self.user_product_index_map(user, add_collaborated = true)
    indexes = Hash.new
    projects = user.projects
    return indexes if projects.nil?

    projects.each do |project|
      next if project.nil?
      project.dependencies.each do |dep|
        next if dep.nil? or dep.product.nil?
        product = dep.product
        prod_id = "#{product.language_esc}_#{product.prod_key}"
        indexes[prod_id] = [] unless indexes.has_key?(prod_id)
        indexes[prod_id] << project[:_id].to_s
      end
    end

    collaborated_projects = Project.by_collaborator(user)
    if add_collaborated and !collaborated_projects.nil?
      collaborated_projects.each do |project|
        next if project.nil?
        project.dependencies.each do |dep|
          next if dep.nil? or dep.product.nil?
          product = dep.product
          prod_id = "#{product.language_esc}_#{product.prod_key}"
          indexes[prod_id] = [] unless indexes.has_key?(prod_id)
          indexes[prod_id] << project[:_id].to_s
        end
      end
    end

    indexes
  end
end
