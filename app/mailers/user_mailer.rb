class UserMailer < ActionMailer::Base
  default from: "\"VersionEye\" <notify@versioneye.com>"
  
  def verification_email(user)
    @user = user
    @verificationlink = "http://localhost:3000/users/activate/#{@user.verification}"
    mail(
      :to => @user.email, 
      :subject => "Verification",
      :tag => "verification"
      )
  end
  
end