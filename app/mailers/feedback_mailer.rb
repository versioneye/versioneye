class FeedbackMailer < ActionMailer::Base

  default from: "\"VersionEye\" <notify@versioneye.com>"

  def feedback_email(name, email, feedback)
    @name = name
    @email = email
    @feedback = feedback
    mail(
      :to => 'reiz@versioneye.com',
      :subject => 'VersionEye Feedback',
      :tag => 'feedback'
      )
  end

end
