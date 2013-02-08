class SubmittedUrlMailer < ActionMailer::Base
  
  default from: "\"VersionEye\" <notify@versioneye.com>"

  def approved_url_email(submitted_url)
    @submitted_url = submitted_url
    @user = submitted_url.user
    mail(
      :to       => @user.email,
      :subject  => "Your submitted Resource is accepted.", 
      :tag      => "notice")
  end

  def declined_url_email(submitted_url)
    @submitted_url = submitted_url
    @user = submitted_url.user
    mail(
      :to       => @user.email,
      :subject  => "You submitted Resource is declined.",
      :tag      => "notice")
  end

  def integrated_url_email(submitted_url, product)
    @submitted_url = submitted_url
    @user = submitted_url.user
    @product = product
    mail(
      :to       => @user.email,
      :subject  => "Your submitted Resource is integrated",
      :tag      => "notice")
  end
  
end
