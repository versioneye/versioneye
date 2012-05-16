class VersioncommentreplyMailer < ActionMailer::Base
  default from: "\"VersionEye\" <notify@versioneye.com>"
  
  def versioncomment_reply_email(comment_user, reply_user, comment, product)
    @comment_user = comment_user
    @reply_user = reply_user
    @comment = comment
    @prod = product
    @commentlink = "#{configatron.server_url}/vc/#{comment.id}"
    mail(
      :to => @comment_user.email, 
      :subject => "#{reply_user.fullname} replied to your comment",
      :tag => "versioncomment"
      )
  end
  
end