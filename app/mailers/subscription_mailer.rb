class SubscriptionMailer < ActionMailer::Base

  default from: "\"VersionEye\" <notify@versioneye.com>"

  def update_subscription( user )
    @user =  user
    mail(
      to: user.email,
      subject: 'VersionEye Subscription',
      tag: 'subscription'
    )
  end

end
