class UserMailer < ActionMailer::Base
  default from: "\"VersionEye\" <notify@versioneye.com>"
  
  def versioncomment_email(product, follower, user, comment)
    @product = product
    @follower = follower
    @user = user
    @commentlink = "http://versioneye.com/vc/#{comment.id}"
    mail(
      :to => @follower.email, 
      :subject => "Comment on Product",
      :tag => "versioncomment"
      )
  end
  
end