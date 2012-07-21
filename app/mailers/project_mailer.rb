class ProjectMailer < ActionMailer::Base
  
  default from: "\"VersionEye\" <notify@versioneye.com>"
  
  def projectnotification_email(project)
    @user = project.user
    @dependencies = project.get_outdated_dependencies
    p "outdated dependencies: #{@dependencies.count}"
    @project_name = project.name
    @link = "#{Settings.server_url}/package/"
    @projectlink = "#{Settings.server_url}/user/projects/#{project.id}"
    mail(
      :to => @user.email, 
      :subject => "Project Notification",
      :tag => "project_notification"
      )
  end
  
end