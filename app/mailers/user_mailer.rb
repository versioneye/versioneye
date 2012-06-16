class UserMailer < ActionMailer::Base
  default from: "\"VersionEye\" <notify@versioneye.com>"
  
  def verification_email(user)
    @user = user
    @verificationlink = "#{Settings.server_url}/users/activate/#{@user.verification}"
    mail(
      :to => @user.email, 
      :subject => "Verification",
      :tag => "verification"
      )
  end
  
  def reset_password(user, new_password)
    @user = user
    @new_password = new_password
    mail(
      :to => @user.email, 
      :subject => "Password Reset",
      :tag => "password_reset"
      )
  end
  
  def new_user_email(user)
    @fullname = user.fullname
    @username = user.username
    mail(
      :to => "robert.reiz.81@gmail.com", 
      :subject => "New User",
      :tag => "new_user"
      )
  end
  
end