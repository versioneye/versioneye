class Settings::EmailsettingsController < ApplicationController

  before_action :authenticate_admin

  def index
    @emailsetting = EmailSettingService.email_setting
    @testemail = ''
  end

  def update
    es = EmailSetting.first
    enable_starttls_auto = params['enable_starttls_auto']
    if enable_starttls_auto.to_s.empty?
      params['enable_starttls_auto'] = false
    end
    if es.update_from params
      EmailSettingService.update_action_mailer es
      flash[:success] = 'Email settings updated'
    else
      flash[:error] = "Something went wrong - #{es.errors.full_messages.to_sentence}"
    end
    redirect_to settings_emailsettings_path
  end

  def test_email
    UserMailer.test_email( params[:testemail] ).deliver
    flash[:success] = "Email is out to #{current_user.email}"
    redirect_to settings_emailsettings_path
  rescue => e
    flash[:error] = "Something went wrong! #{e.message}"
    Rails.logger.error e.message
    redirect_to settings_emailsettings_path
  end

end
