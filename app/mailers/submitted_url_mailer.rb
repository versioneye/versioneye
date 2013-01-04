class SubmittedUrlMailer < ActionMailer::Base
  
  default from: "\"VersionEye\" <notify@versioneye.com>"

  def approved_url_email(user_email, submitted_url)
    @submitted_url = submitted_url
    mail(
      :to       => user_email,
      :subject  => "Your URL is accepted.", 
      :tag      => "notice")
  end

  def declined_url_email(user_email, submitted_url)
    @submitted_url = submitted_url
    mail(
      :to       => user_email,
      :subject  => "You URL is declined.",
      :tag      => "notice")
  end

  def integrated_url_email(user_email, submitted_url, product)
    @submitted_url = submitted_url.url
    @product = product
    mail(
      :to       => user_email,
      :subject  => "We accepted your's submition for VersionEye.",
      :tag      => "notice")
  end
  
end
