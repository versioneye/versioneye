class ProjectMailer < ActionMailer::Base

  default from: "\"VersionEye\" <notify@versioneye.com>"

  # TODO refactor this email. Send only link to project on VersionEye.
  def projectnotification_email( project, user = nil )
    @user = user
    @user = project.user if user.nil?
    deps          = project.outdated_dependencies
    @dependencies = Hash.new
    deps.each do |dep|
      @dependencies[dep.name] = dep
    end
    @project_name = project.name
    @projectlink  = "#{Settings.server_url}/user/projects/#{project.id}"

    email = user ? user.email : Project.email_for(project, @user)

    mail(
      :to      => email,
      :subject => "Project Notification for #{project.name}",
      :tag     => 'project_notification'
      )
  end

end
