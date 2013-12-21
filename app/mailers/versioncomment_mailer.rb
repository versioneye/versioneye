class VersioncommentMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"VersionEye\" <notify@versioneye.com>"

  def versioncomment_email(product, follower, user, comment)
    @prod = product
    @follower = follower
    @user = user
    @commentlink = "#{Settings.server_url}/vc/#{comment.id}"
    mail(
      :to => @follower.email,
      :subject => 'Comment on Package',
      :tag => 'versioncomment'
      )
  end

end
