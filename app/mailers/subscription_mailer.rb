class SubscriptionMailer < ActionMailer::Base

  layout 'email_html_layout'
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
