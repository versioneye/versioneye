class ProjectService

  def self.type_by_filename filename
    return nil if filename.to_s.empty?
    trimmed_name = filename.split('?')[0]
    return Project::A_TYPE_RUBYGEMS  if trimmed_name.match(/Gemfile$/)          or trimmed_name.match(/Gemfile.lock$/)
    return Project::A_TYPE_COMPOSER  if trimmed_name.match(/composer.json$/)    or trimmed_name.match(/composer.lock$/)
    return Project::A_TYPE_PIP       if trimmed_name.match(/requirements.txt$/) or trimmed_name.match(/setup.py$/) or trimmed_name.match(/pip.log$/)
    return Project::A_TYPE_NPM       if trimmed_name.match(/package.json$/)
    return Project::A_TYPE_GRADLE    if trimmed_name.match(/.gradle$/)
    return Project::A_TYPE_MAVEN2    if trimmed_name.match(/pom.xml$/) or trimmed_name.match(/pom.json$/)
    return Project::A_TYPE_LEIN      if trimmed_name.match(/project.clj$/)
    return Project::A_TYPE_BOWER     if trimmed_name.match(/^bower.json$/)
    return Project::A_TYPE_COCOAPODS if trimmed_name.match(/Podfile$/) or trimmed_name.match(/.podfile$/) or trimmed_name.match(/Podfile.lock$/)
    return nil
  end

  def self.store project
    return false if project.nil?

    project.make_project_key!
    project.save
    if project.dependencies && !project.dependencies.empty? && project.save
      project.save_dependencies
      return true
    else
      p project
      p "Can't save project: #{project.errors.full_messages.to_json}"
      Rails.logger.error "Can't save project: #{project.errors.full_messages.to_json}"
      return false
    end
  end

  def self.update_all period
    update_projects period
    update_collaborators_projects period
  end

  def self.update_projects period
    projects = Project.by_period period
    projects.each do |project|
      self.update( project, true )
    end
  end

  def self.update_collaborators_projects period
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

  def self.update project, send_email = false
    return nil if project.nil?
    return nil if project.user_id.nil? || project.user.nil?
    return nil if project.user.deleted
    self.update_url project
    new_project = self.build_from_url project.url
    project.update_from new_project
    update_badge_for_project( project )
    if send_email && project.out_number > 0 && project.user.email_inactive == false
      Rails.logger.info "send out email notification for project: #{project.name} to user #{project.user.fullname}"
      ProjectMailer.projectnotification_email( project ).deliver
    end
    project
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
    nil
  end

  def self.update_url project
    if project.source.eql?( Project::A_SOURCE_GITHUB )
      self.update_project_file_from_github( project )
    elsif project.source.eql?( Project::A_SOURCE_BITBUCKET )
      self.update_project_file_from_bitbucket( project )
    end

    if project.s3_filename && !project.s3_filename.empty?
      project.url = S3.url_for( project.s3_filename )
    end
  end

  def self.update_project_file_from_github project
    project_file = Github.fetch_project_file_from_branch project.scm_fullname, project.filename, project.scm_branch, project.user.github_token
    if project_file.to_s.strip.empty?
      Rails.logger.error "Importing project file from Github failed."
      return nil
    end

    s3_infos = S3.upload_github_file( project_file, project_file[:name] )
    update_project_with_s3_file project, s3_infos
  end

  def self.update_project_file_from_bitbucket project
    user = project.user
    project_content = Bitbucket.fetch_project_file_from_branch project.scm_fullname, project.scm_branch, project.filename, user.bitbucket_token, user.bitbucket_secret
    if project_content.nil? || project_content.to_s.empty?
      Rails.logger.error "Importing project file from BitBucket failed."
      return nil
    end

    s3_infos = S3.upload_file_content( project_content, project.filename )
    update_project_with_s3_file project, s3_infos
  end

=begin
  This methods is doing 3 things
   - Importing a project_file from GitHub
   - Parsing the project_file to a new project
   - Storing the new project to DB
=end
  def self.import_from_github user, repo_name, filename, branch = "master", fileurl = nil
    private_project = Github.private_repo? user.github_token, repo_name
    unless allowed_to_add_project?(user, private_project)
      return "Please upgrade your plan to monitor the selected project."
    end

    if fileurl
      project_file = Github.fetch_project_file_directly(filename, branch, fileurl, user[:github_token])
    else
      project_file = Github.fetch_project_file_from_branch(repo_name, filename, branch, user[:github_token] )
    end

    if project_file.nil?
      error_msg = " Didn't find any project file of a supported package manager."
      Rails.logger.error " Can't import project file `#{filename}` from #{repo_name} branch #{branch} "
      return error_msg
    end

    s3_info = S3.upload_github_file( project_file, project_file[:name] )
    if s3_info.nil? && !s3_info.has_key?('filename') && !s3_info.has_key?('s3_url')
      error_msg = "Connectivity issues - can't import project file for parsing."
      Rails.logger.error " Can't upload file to s3: #{project_file[:name]}"
      return error_msg
    end

    parsed_project = build_from_url s3_info['s3_url']
    parsed_project.update_attributes({
      name: repo_name,
      project_type: project_file[:type],
      user_id: user.id.to_s,
      source: Project::A_SOURCE_GITHUB,
      private_project: private_project,
      scm_fullname: repo_name,
      scm_branch: branch,
      s3_filename: s3_info['filename'],
      url: s3_info['s3_url']
    })

    return parsed_project if store( parsed_project )
  end

=begin
  This methods is doing 3 things
   - Importing a project_file from Bitbucket
   - Parsing the project_file to a new project
   - Storing the new project to DB
=end

  def self.import_from_bitbucket(user, repo_name, filename, branch = "master")
    repo = BitbucketRepo.by_user(user).by_fullname(repo_name).shift
    private_project = repo[:private]
    unless allowed_to_add_project?(user, private_project)
      return "Please upgrade your plan to monitor the selected project."
    end

    content = Bitbucket.fetch_project_file_from_branch(
      repo_name, branch, filename, user[:bitbucket_token], user[:bitbucket_secret]
    )
    if content.nil? or content == "error"
      error_msg = " Didn't find any project file of a supported package manager."
      Rails.logger.error " Can't import project file `#{filename}` from #{repo_name} branch #{branch} "
      return error_msg
    end

    s3_info = S3.upload_file_content(content, filename)
    if s3_info.nil? && !s3_info.has_key?('filename') && !s3_info.has_key?('s3_url')
      error_msg = "Connectivity issues - can't import project file for parsing."
      Rails.logger.error " Can't upload file to s3: #{project_file[:name]}"
      return error_msg
    end

    project_type = ProjectService.type_by_filename(filename)
    parsed_project = build_from_url(s3_info['s3_url'], project_type)
    parsed_project.update_attributes({
      name: repo_name,
      project_type: project_type,
      user_id: user.id.to_s,
      source: Project::A_SOURCE_BITBUCKET,
      scm_fullname: repo_name,
      scm_branch: branch,
      private_project: private_project,
      s3_filename: s3_info['filename'],
      url: s3_info['s3_url']
    })

    return parsed_project if store( parsed_project )
 end

  def self.build_from_url(url, project_type = nil)
    project_type = type_by_filename(url) if project_type.nil?
    parser       = ParserStrategy.parser_for( project_type, url )
    parser.parse url
  rescue => e
    Rails.logger.error "Error in build_from_url(url) -> e.message"
    Rails.logger.error e.backtrace.join("\n")
    Project.new
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

  def self.allowed_to_add_project?( user, private_project )
    return true if !private_project
    private_project_count = Project.private_project_count_by_user( user.id )
    max = user.free_private_projects
    if user.plan
      max += user.plan.private_projects
    end
    return false if private_project_count >= max
    return true
  end

  # Returns a map with
  #  - :key => "language_prod_key"
  #  - :value => "Array of project IDs where the prod_key is used"
  def self.user_product_index_map user, add_collaborated = true
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

  def self.badge_for_project project_id
    badge = Rails.cache.read project_id
    return badge if badge

    project = Project.find_by_id project_id
    return "unknown" if project.nil?

    update_badge_for_project project
  end

  def self.update_badge_for_project project
    badge    = project.outdated? ? "out-of-date" : "up-to-date"
    Rails.cache.write( project.id.to_s, badge, timeToLive: 1.day)
    badge
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join "\n"
    "unknown"
  end

  private

    def update_project_with_s3_file project, s3_infos
      return false unless s3_infos && s3_infos['filename'] && s3_infos['s3_url']

      S3.delete( project.s3_filename )
      project.s3_filename = s3_infos['filename']
      project.url         = s3_infos['s3_url']
      project.save
    end

end
