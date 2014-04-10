class Settings::EmailsettingsController < ApplicationController

  before_filter :authenticate

  def index
    @emailsetting = EmailSetting.first
  end

  def update
    es = EmailSetting.first
    if es.update_attributes params
      flash[:success] = 'Email settings updated'
    else
      flash[:error] = "Something went wrong - #{es.errors.full_messages.to_sentence}"
    end
    redirect_to settings_emailsettings_path
  end

end
