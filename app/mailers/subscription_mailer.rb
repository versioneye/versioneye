class SubscriptionMailer < ActionMailer::Base
  default from: "\"VersionEye\" <notify@versioneye.com>"

  def success_email(user)
    @user =  user
    mail(
      to: user.email,
      subject: "VersionEye subscription was successful.",
      tag: "subscription"
    )
  end
end
