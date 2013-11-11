class NewsletterMailer < ActionMailer::Base

  default from: "\"VersionEye\" <notify@versioneye.com>"

  def newsletter_new_features_email(user)
    @user = user
    mail(
      :to => @user.email,
      :subject => "New Features - OpenSearch + More Speed.",
      :tag => "newsletter"
      )
  end

end
