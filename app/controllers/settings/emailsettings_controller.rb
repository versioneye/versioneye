class Settings::EmailsettingsController < ApplicationController

  before_filter :authenticate_admin

  def index
    @emailsetting = EmailSettingService.email_setting
  end

  def update
    es = EmailSetting.first
    if es.update_attributes params
      EmailSettingService.update_action_mailer es
      flash[:success] = 'Email settings updated'
    else
      flash[:error] = "Something went wrong - #{es.errors.full_messages.to_sentence}"
    end
    redirect_to settings_emailsettings_path
  end

end
