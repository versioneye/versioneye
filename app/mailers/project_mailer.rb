class ProjectMailer < ActionMailer::Base
  
  default from: "\"VersionEye\" <notify@versioneye.com>"
  
  def projectnotification_email( project )
    @user = project.user
    @dependencies = project.outdated_dependencies
    @project_name = project.name
    @link = "#{Settings.server_url}/package/"
    @projectlink = "#{Settings.server_url}/user/projects/#{project.id}"
    email = Project.email_for(project, @user)
    mail(
      :to => email, 
      :subject => "Project Notification for #{project.name}",
      :tag => "project_notification"
      )
  end
  
end