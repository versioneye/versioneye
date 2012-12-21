class FollowerMailer < ActionMailer::Base
  default from: "\"VersionEye\" <notify@versioneye.com>"

  def non_follower_email(user, subject = nil)
    @user = user
    mail(
      :to => user.email,
      :subject => (subject or "Dont miss opportunity!"),
      :tag => "marketing"
      )

  end
end
