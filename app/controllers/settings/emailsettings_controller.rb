class Settings::EmailsettingsController < ApplicationController

  before_filter :authenticate_admin

  def index
    @emailsetting = EmailSettingService.email_setting
  end

  def update
    es = EmailSetting.first
    enable_starttls_auto = params['enable_starttls_auto']
    if enable_starttls_auto.to_s.empty?
      params['enable_starttls_auto'] = false
    end
    if es.update_attributes params
      EmailSettingService.update_action_mailer es
      flash[:success] = 'Email settings updated'
    else
      flash[:error] = "Something went wrong - #{es.errors.full_messages.to_sentence}"
    end
    redirect_to settings_emailsettings_path
  end

  def test_email
    UserMailer.suggest_packages_email( current_user ).deliver
    flash[:success] = "Email is out to #{current_user.email}"
    redirect_to settings_emailsettings_path
  rescue => e
    flash[:error] = "Something went wrong! It's your fault! - #{e.message}"
    Rails.logger.error e.message
    redirect_to settings_emailsettings_path
  end

end
