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
    p "user: #{project.user.username}  #{project.name} url: #{project.url}"
    p " - old deps: #{project.dep_number} - out: #{project.out_number}"
    new_project = self.create_from_url( project.url )
    p " - new deps: #{new_project.dep_number} - out: #{new_project.out_number}"
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
    p "ERROR in proccess_project #{e}"
    e.backtrace.each do |message|
      p "#{message}"
    end
    nil
  end

  # Fetch the project file from GitHub, store it on S3 and 
  # update the s3_filename & url in the project instance 
  # 
  def self.update_from_github( project )
    github_project = project.github_project
    current_user = project.user
    sha = Github.get_repo_sha( github_project, current_user.github_token )
    project_info = Github.get_project_info( github_project, sha, current_user.github_token )
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

  def self.create_from_url( url )
    project_type = Project.type_by_filename( url )
    parser = ParserStrategy.parser_for( project_type, url )
    parser.parse url 
  rescue => e 
    p "exception: #{e}"
    e.backtrace.each do |message|
      p "#{message}"
    end
    project = Project.new
  end

end
