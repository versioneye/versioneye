class UserMailer < ActionMailer::Base
  
  default from: "\"VersionEye\" <notify@versioneye.com>"

  def receipt_email(user)
    @user = user
    @plan = user.plan
    @billing_address = user.billing_address
    mail(
      :to => user.email, 
      :subject => "Receipt",
      :tag => "receipt"
      )
  end
  
  def verification_email(user, verification, email)
    @user = user
    @verificationlink = "#{Settings.server_url_https}/users/activate/#{verification}"
    mail(
      :to => email, 
      :subject => "Verification",
      :tag => "verification"
      )
  end

  def verification_email_only(user, verification, email)
    @user = user
    @verificationlink = "#{Settings.server_url_https}/users/activate/#{verification}"
    mail(
      :to => email, 
      :subject => "Verification",
      :tag => "verification"
      )
  end

  def verification_email_reminder(user, verification, email)
    @user = user
    @verificationlink = "#{Settings.server_url_https}/users/activate/#{verification}"
    mail(
      :to => email, 
      :subject => "Verification Reminder",
      :tag => "verification_reminder"
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
