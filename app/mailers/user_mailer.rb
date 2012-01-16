class UserMailer < ActionMailer::Base
  default from: "\"VersionEye\" <notify@versioneye.com>"
  
  def verification_email(user)
    p 'verificaiton_email'
    @user = user
    @verificationlink = "http://versioneye-beta.com/users/activate/#{@user.verification}"
    mail(
      :to => @user.email, 
      :subject => "Verification",
      :tag => "verification"
      )
  end
  
end