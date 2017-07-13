class UnsubscribeController < ApplicationController


  def unsubscribe 
    encrypted_email = params[:email]
    newsletter     = params[:newsletter]

    email = [encrypted_email].pack("H*")
    user  = User.find_by_email( email )

    if user.nil? 
      flash.now[:error] = "We are not able to find a user to this unsubscribe link. Please contact VersionEye on Twitter."  
      return 
    end

    uns = UserNotificationSetting.fetch_or_create_notification_setting user
    if newsletter.eql?('newsletter_news')
      uns.newsletter_news = false 
      uns.save 
    elsif newsletter.eql?('newsletter_features')
      uns.newsletter_features = false 
      uns.save 
    elsif newsletter.eql?('notification_emails')
      uns.notification_emails = false 
      uns.save 
    elsif newsletter.eql?('project_emails')
      uns.project_emails = false 
      uns.save 
    end
    flash.now[:success] = "You are successfully unsubscribed from the newsletter `#{newsletter}`."
  rescue => e
    logger.error "ERROR in unsubscribe: #{e.message}"
    logger.error e.stacktrace.join "\n"
    flash.now[:error] = "Someting went wrong. Please contact VersionEye on Twitter."
  end


end
