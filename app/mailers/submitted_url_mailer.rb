class SubmittedUrlMailer < ActionMailer::Base
  
  default from: "\"VersionEye\" <notify@versioneye.com>"

  def approved_url_email(user_email, submitted_url)
      @submitted_url = submitted_url
      mail(
          :to       => user_email,
          :subject  => "Your URL is accepted.", 
          :tag      => "notice")
  end

end