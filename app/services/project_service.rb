class ProjectService

  def self.update_dependencies( period )
    projects = Project.all()
    projects.each do |project|
      if project.period.eql?( period )
        self.process_project ( project )
      end
    end
  end

  def self.process_project( project )
    if project.nil? || project.user_id.nil?
      return nil
    end
    if project.source.eql?( Project::A_SOURCE_GITHUB )
      self.update_from_github( project )
    end
    if project.s3_filename && !project.s3_filename.empty?
      project.url = S3.url_for( project.s3_filename )
    end
    new_project = self.create_from_url( project.url )
    if new_project.dependencies && !new_project.dependencies.empty?
      project.overwrite_dependencies( new_project.dependencies )
      project.out_number = new_project.out_number
      project.dep_number = new_project.dep_number
      project.unknown_number = new_project.unknown_number
      project.save
      if project.out_number > 0
        ProjectMailer.projectnotification_email( project ).deliver
      end
    end
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    nil
  end

  # Fetch the project file from GitHub, store it on S3 and
  # update the s3_filename & url in the project instance
  #
  def self.update_from_github( project )
    github_project = project.github_project
    current_user   = project.user
    sha = Github.get_repo_sha( github_project, current_user.github_token )
    project_info = Github.repository_info( github_project, sha, current_user.github_token )
    if project_info.empty?
      return nil
    end
    file = Github.fetch_file( project_info['url'], current_user.github_token )
    s3_infos = S3.upload_github_file( file, project_info['name'] )
    if s3_infos['filename'] && s3_infos['s3_url']
      S3.delete( project.s3_filename )
      project.s3_filename = s3_infos['filename']
      project.url = s3_infos['s3_url']
      project.save
    end
  end

=begin
  Imports project file from github branches;
  It's more general version of previous update_from_github
=end
  def self.import_from_github(user, repo_name, branch = "master")
    private_project = Github.private_repo?(user.github_token, repo_name)

    if private_project && !ProjectService.is_allowed_to_add_private_project?(user)
      flash[:error] = "You selected a private project. Please upgrade your plan to monitor the selected project."
      return nil
    end

   github_file = Github.import_from_branch(user, repo_name, branch)
    if github_file.nil?
      Rails.logger.error "Cant import project file from #{repo_name} branch #{branch} "
      return nil
    end
    
    s3_info = S3.upload_github_file(github_file, github_file['name'])
    if s3_info.nil? && !s3_info.has_key?('filename') && !s3_info.has_key?('s3_url')
      Rails.logger.error "Cant upload file to s3: #{github_file['name']}" 
      return nil
    end

    new_project = Project.new name: github_file['name'],
                              project_type: github_file['type'],
                              user_id: user.id.to_s,
                              source: Project::A_SOURCE_GITHUB,
                              github_project: repo_name,
                              private_project: private_project,
                              github_branch: branch,
                              s3_filename: s3_info['filename'],
                              url: s3_info['s3_url']

    parsed_project = parse_from_url new_project.url
    parsed_project.update_attributes(new_project.attributes)
    
    return parsed_project
  end

  def self.is_allowed_to_add_private_project?(user)
    private_projects = Project.find_private_projects_by_user(user.id)
    plan = user.plan
    if plan.nil?
      error_msg = "Current plan doesnt allow to add private project. Please update your plan."
      flash[:error] = error_msg
      return false
    elsif plan.private_projects > private_projects.count
      return true
    else
      return false
    end
  end

  def self.parse_from_url( url )
    project_type = Project.type_by_filename( url )
    parser = ParserStrategy.parser_for( project_type, url )
    parser.parse url
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    project = Project.new
  end


  def self.create_from_url( url )
    project_type = Project.type_by_filename( url )
    parser = ParserStrategy.parser_for( project_type, url )
    parser.parse url
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    project = Project.new
  end

  def self.destroy_project project_id
    project = Project.find_by_id( project_id )
    if project.s3_filename && !project.s3_filename.empty?
      S3.delete( project.s3_filename )
    end
    project.fetch_dependencies
    project.dependencies.each do |dep|
      dep.remove
    end
    project.remove
  end

end
